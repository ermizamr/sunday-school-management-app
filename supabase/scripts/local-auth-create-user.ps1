param(
  [Parameter(Mandatory = $true)]
  [string]$Email,

  [Parameter(Mandatory = $true)]
  [string]$Password,

  # Defaults to local Supabase.
  [string]$ProjectUrl = "http://127.0.0.1:54321",

  # If omitted, pulled from `supabase status -o json`.
  [string]$SecretKey,

  # If provided, will upsert a row into public.profiles for this user.
  [string]$AcademicId,
  [string]$Name,
  [ValidateSet('admin', 'servant', 'student')]
  [string]$Role,
  [ValidateSet('active', 'inactive')]
  [string]$AccountStatus
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Decode-Base64Url([string]$s) {
  $b64 = $s.Replace('-', '+').Replace('_', '/')
  switch ($b64.Length % 4) {
    2 { $b64 += '==' ; break }
    3 { $b64 += '=' ; break }
    0 { break }
    default { throw "Invalid base64url length: $($b64.Length)" }
  }
  return [Convert]::FromBase64String($b64)
}

function Encode-Base64Url([byte[]]$bytes) {
  return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function Convert-DerEcdsaToP1363([byte[]]$der, [int]$fieldBytes) {
  $offset = 0
  if ($der[$offset] -ne 0x30) { throw 'Not a DER sequence' }
  $offset++

  $seqLenByte = $der[$offset]
  $offset++
  if ($seqLenByte -band 0x80) {
    $lenBytes = $seqLenByte -band 0x7F
    $seqLen = 0
    for ($i = 0; $i -lt $lenBytes; $i++) {
      $seqLen = ($seqLen * 256) + $der[$offset + $i]
    }
    $offset += $lenBytes
  }

  if ($der[$offset] -ne 0x02) { throw 'Expected INTEGER (r)' }
  $offset++
  $lenR = $der[$offset]
  $offset++
  $r = $der[$offset..($offset + $lenR - 1)]
  $offset += $lenR

  if ($der[$offset] -ne 0x02) { throw 'Expected INTEGER (s)' }
  $offset++
  $lenS = $der[$offset]
  $offset++
  $s = $der[$offset..($offset + $lenS - 1)]

  if ($r.Length -gt $fieldBytes) { $r = $r[($r.Length - $fieldBytes)..($r.Length - 1)] }
  if ($s.Length -gt $fieldBytes) { $s = $s[($s.Length - $fieldBytes)..($s.Length - 1)] }

  $rPad = New-Object byte[] $fieldBytes
  $sPad = New-Object byte[] $fieldBytes
  [Array]::Copy($r, 0, $rPad, $fieldBytes - $r.Length, $r.Length)
  [Array]::Copy($s, 0, $sPad, $fieldBytes - $s.Length, $s.Length)

  return $rPad + $sPad
}

if (-not $SecretKey) {
  $statusJson = (supabase status -o json) | ConvertFrom-Json
  if (-not $statusJson.SECRET_KEY) {
    throw 'Could not find SECRET_KEY in `supabase status -o json` output.'
  }
  $SecretKey = $statusJson.SECRET_KEY
}

$jwkJson = (docker exec supabase_auth_ss-management-system printenv GOTRUE_JWT_KEYS).Trim()
$issuer = (docker exec supabase_auth_ss-management-system printenv GOTRUE_JWT_ISSUER).Trim()
$aud = (docker exec supabase_auth_ss-management-system printenv GOTRUE_JWT_AUD).Trim()

$jwk = (ConvertFrom-Json $jwkJson)[0]

$x = Decode-Base64Url $jwk.x
$y = Decode-Base64Url $jwk.y
$d = Decode-Base64Url $jwk.d

$ecParams = New-Object System.Security.Cryptography.ECParameters
$p256Oid = New-Object System.Security.Cryptography.Oid('1.2.840.10045.3.1.7')
$ecParams.Curve = [System.Security.Cryptography.ECCurve]::CreateFromOid($p256Oid)
$q = New-Object System.Security.Cryptography.ECPoint
$q.X = $x
$q.Y = $y
$ecParams.Q = $q
$ecParams.D = $d

$ecdsa = New-Object System.Security.Cryptography.ECDsaCng
$ecdsa.ImportParameters($ecParams)

$now = [DateTimeOffset]::UtcNow
$payload = @{
  iss = $issuer
  aud = $aud
  role = 'service_role'
  iat = [int]$now.ToUnixTimeSeconds()
  exp = [int]$now.AddMinutes(10).ToUnixTimeSeconds()
}
$header = @{
  alg = 'ES256'
  typ = 'JWT'
  kid = $jwk.kid
}

$headerB64 = Encode-Base64Url ([Text.Encoding]::UTF8.GetBytes(($header | ConvertTo-Json -Compress)))
$payloadB64 = Encode-Base64Url ([Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Compress)))
$signingInput = "$headerB64.$payloadB64"
$hash = (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::ASCII.GetBytes($signingInput))
$sig = $ecdsa.SignHash($hash)
$rawSig = if ($sig.Length -eq 64) { $sig } else { Convert-DerEcdsaToP1363 $sig 32 }
$sigB64 = Encode-Base64Url $rawSig
$jwt = "$signingInput.$sigB64"

$authHeaders = @{
  apikey = $SecretKey
  Authorization = "Bearer $jwt"
}

$createUserBody = @{
  email = $Email
  password = $Password
  email_confirm = $true
}

$user = Invoke-RestMethod -Uri "$ProjectUrl/auth/v1/admin/users" -Method Post -Headers $authHeaders -ContentType 'application/json' -Body ($createUserBody | ConvertTo-Json)

if ($AcademicId -and $Role -and $AccountStatus) {
  $profileHeaders = @{
    apikey = $SecretKey
    Prefer = 'resolution=merge-duplicates,return=representation'
  }

  $profileBody = @{
    id = $user.id
    academic_id = $AcademicId
    role = $Role
    account_status = $AccountStatus
    name = $Name
  }

  $null = Invoke-RestMethod -Uri "$ProjectUrl/rest/v1/profiles?on_conflict=id" -Method Post -Headers $profileHeaders -ContentType 'application/json' -Body ($profileBody | ConvertTo-Json)
}

$user | ConvertTo-Json -Depth 10
