# የአስተዳዳሪ ዳሽቦርድ መመሪያ (Admin Dashboard Guide — አማርኛ)

ይህ ሰነድ በ `admin-panel/` ውስጥ ያለውን **የአስተዳዳሪ ፖርታል (Admin Portal)** የድር ዳሽቦርድ እንዴት እንደሚጠቀሙ ይገልጻል።

የሚሸፍነው፦
- መግባት (sign in) እና አሰሳ (navigation)
- እያንዳንዱ ገጽ ምን እንደሚያደርግ (ዓላማ፣ መስኮች፣ እርምጃዎች፣ ማረጋገጫ/Validation፣ ፈቃዶች)
- ዋና የሥራ ፍሰቶች (የትምህርት ዓመት አስተዳደር፣ ፕሮሞሽን፣ ማስታወቂያ)
- ምርጥ ልምዶች እና ለተጠንቀቁ እርምጃዎች ማስጠንቀቂያዎች
- ቀላል የውሂብ ሞዴል (ለአስተዳዳሪ ተገቢ)
- ስህተት አስተዳደር እና መፍትሄ መፈለጊያ (troubleshooting)

---

## የይዘት ማውጫ (Table of contents)

- 1) አጠቃላይ
- 2) መድረሻ እና መግቢያ
- 3) የአሰሳ መዋቅር
- 4) ምንን ለምን ይጠቀሙ (What to use for what)
- 5) ዳሽቦርድ (ምን ያሳያል)
- 6) ገጽ-በ-ገጽ መግለጫ
  - 6.1) ተማሪዎች (Students)
  - 6.2) ተመራቂዎች (Graduates)
  - 6.3) አገልጋዮች (Servants)
  - 6.4) ደረጃዎች (Grades)
  - 6.5) ትምህርቶች (Subjects)
  - 6.6) የትምህርት ዓመት (Academic Year)
  - 6.7) ፕሮሞሽን (Promotions)
  - 6.8) ማስታወቂያዎች (Announcements)
- 7) የሥራ ፍሰቶች (Workflows)
- 8) ምርጥ ልምዶች (Best practices)
- 9) ተጠንቀቁ የሚገባቸው እርምጃዎች እና ማስጠንቀቂያዎች
- 10) የውሂብ ሞዴል (አስተዳዳሪ-ተገቢ)
- 11) ስህተት አስተዳደር እና መፍትሄ መፈለጊያ
- 12) የዲቨሎፐር ማስታወሻ (አማራጭ)

---

## 1) አጠቃላይ

የአስተዳዳሪ ፖርታል አስተዳዳሪዎች ለሚከተሉት ዋና የስርዓት ውሂቦች እና ሂደቶች ይጠቀሙበታል፦
- የተማሪ እና የአገልጋይ መለያዎች
- ደረጃዎች (Grades) እና ትምህርቶች (Subjects)
- የትምህርት ዓመት እና ሴሚስተሮች አስተዳደር
- ፕሮሞሽን (መመዘኛ ማቀናበር + ማስኬድ)
- ማስታወቂያዎች (እና push notification)
- ተመራቂዎች ዝርዝር (read-only)

**ፈቃድ/Permissions (አጠቃላይ)፦**
- ሁሉም `/admin/*` ገጾች በ UI ደረጃ የተጠበቁ ናቸው፤ `profiles.role = 'admin'` ያልሆነ ተጠቃሚ መግባት አይችልም።
- አንዳንድ እጅግ አስፈላጊ እርምጃዎች በ server-side ደረጃም (RPC እና Edge Functions) በጥብቅ ይጠበቃሉ።

---

## 2) መድረሻ እና መግቢያ (Access & sign-in)

### የመግቢያ ገጽ (Where to sign in)
- ከ Admin Portal አድራሻ ጋር በማሄድ፣ ካልገቡ ወደ መግቢያ ገጽ በራሱ ይመራዎታል።
- የመግቢያ መንገድ (route)፦ `/sign-in`

### መለያ መረጃ (Credentials)
- መግባት በ **ኢሜይል + የይለፍ ቃል** ይፈጸማል።
- መለያዎ `admin` ካልሆነ ወዲያውኑ ይወጣ (sign out) እና ወደ `/sign-in` ይመለሳሉ።

### ከመግባት በኋላ (After sign-in)
- ከሌላ ገጽ ተመርተው ከመጡ ወደ ያ ቀድሞ ያለው ገጽ ይመለሳሉ።
- ካልሆነ በነባሪ **የትምህርት ዓመት (Academic Year)** ገጽ ይከፈታል።

### መውጫ (Sign out)
- በ sidebar ውስጥ ያለውን **Sign Out** ይጠቀሙ።

---

## 3) የአሰሳ መዋቅር (Navigation structure)

በ sidebar የሚታዩ ገጾች (ቅደም ተከተል)፦
1. Dashboard
2. Students
3. Servants
4. Grades
5. Subjects
6. Academic Year
7. Promotions
8. Announcements
9. Graduates

---

## 4) ምንን ለምን ይጠቀሙ (What to use for what)

- **አዲስ ተማሪ መፍጠር** → Students
- **የተማሪ ደረጃ (grade) መቀየር** → Students
- **የይለፍ ቃል መቀየር/ማስጀመር (reset password)** → Students
- **ተማሪ/አገልጋይ አካውንት ማቋረጥ ወይም ማንቃት** → Students / Servants
- **ደረጃዎችን ማቀናበር (1ኛ–4ኛ ወዘተ)** → Grades
- **ትምህርቶችን ለእያንዳንዱ ደረጃ መዘርዘር** → Subjects
- **የትምህርት ቅድመ-ትምህርት (prerequisite) ማቀናበር** → Subjects
- **አዲስ የትምህርት ዓመት መጀመር** → Academic Year
- **Semester 1 መጨረሻ / Semester 2 መጀመር** → Academic Year
- **የትምህርት ዓመት መጨረስ** → Academic Year
- **የፕሮሞሽን መመዘኛ (criteria) ማቀናበር** → Promotions
- **ፕሮሞሽን ማስኬድ (ለሁሉም ደረጃዎች)** → Promotions
- **ማስታወቂያ መፍጠር (እና push notification)** → Announcements
- **ተመራቂ ተማሪዎችን መመልከት** → Graduates

---

## 5) ዳሽቦርድ (Dashboard — ምን ያሳያል)

**ዓላማ:** ፈጣን አጠቃላይ እይታ (snapshot)።

**የሚያሳየው:**
- የተማሪዎች ብዛት (`profiles` ውስጥ `role = 'student'`)
- የአገልጋዮች ብዛት (`role = 'servant'`)
- የማስታወቂያዎች ብዛት
- አሁን ንቁ (active) የሆነ የትምህርት ዓመት ስም (ካልነበረ “no active year” ይላል)

**እርምጃዎች:** የለም (read-only)።

---

## 6) ገጽ-በ-ገጽ መግለጫ (Page-by-page reference)

### 6.1) ተማሪዎች (Students)

**ዓላማ**
- አዲስ የተማሪ አካውንት መፍጠር
- የተማሪዎች ደረጃ (grade) መመደብ/መቀየር
- የይለፍ ቃል ማስጀመር (reset)
- አካውንት ማንቃት/ማቋረጥ

**የሚታየው**
- የተማሪ መገለጫዎች (`profiles.role = 'student'`)
- የሁኔታ ማጣሪያ (status filter): `All / Active / Inactive`
- መፈለጊያ (search): በ **ስም**, **academic ID**, ወይም በ **internal user id** ይመጣጠናል

**ተማሪ መፍጠር: መስኮች**
- **Academic ID (አማራጭ)**
  - ካስገቡ፣ ቅርጹ `xxxx/xx` መሆን አለበት (ምሳሌ: `0001/17`)።
  - ካትጨምሩት፣ ስርዓቱ ለአሁኑ የኢትዮጵያ ዓመት ቀጣዩን የሚገኝ ቁጥር በራሱ ይመድባል (ምሳሌ: `0001/yy`, `0002/yy`, …)።
- **ስም (አስፈላጊ)**
- **የይለፍ ቃል (አማራጭ)**
  - ካልተሞላ፣ በነባሪ ከ academic ID ጋር እኩል ይሆናል።
  - academic ID በራሱ ከተመደበ፣ የይለፍ ቃሉም ያ የተመደበ academic ID ይሆናል።
- **ኢሜይል (አማራጭ)**
  - ካልተሞላ፣ backend ውስጥ የሚጠቅም የመለያ ኢሜይል በራሱ ይፈጥራል።
- **ደረጃ/Grade (አስፈላጊ)**

**ተማሪ መፍጠር: እርምጃ**
- **Create**
  - academic ID በራሱ ከተመደበ፣ ፖርታሉ የተመደበውን academic ID በ alert ያሳያል።

**ተማሪ ማሻሻል (edit): መስኮች/እርምጃዎች**
- **Grade dropdown** (ለእያንዳንዱ ተማሪ)
  - ደረጃውን ቀይረው **Save** ይጫኑ።
  - ማስታወሻ፦ UI ባዶ ደረጃ መተው ምናልባት ያስችላል፣ ግን ተማሪውን ያለ ደረጃ መተው የደረጃ-ተመራ ሂደቶችን ሊያበላሽ ይችላል።

**የይለፍ ቃል ማስጀመር (Reset password)**
- **Reset Password** ይጫኑ
- በ prompt ውስጥ አዲስ የይለፍ ቃል ያስገቡ
- ወዲያውኑ ይቀየራል

**አካውንት ማንቃት/ማቋረጥ**
- **Deactivate** ከተጫነ፣ ሁኔታው `inactive_pending_admin` ይሆናል።
- **Activate** ከተጫነ፣ ሁኔታው `active` ይሆናል።
- ማረጋገጫ (confirm) ይጠየቃል።
- ተመራቂ (`graduated`) ተማሪዎች ሁኔታ ለመቀየር read-only እንደሆኑ ይቆጠራሉ።

**ማረጋገጫ/Validation እና ገደቦች**
- መፍጠር ላይ `name` እና `grade` አስፈላጊ ናቸው።
- Academic ID ካስገቡ ቅርጹ `xxxx/xx` መሆን አለበት።
- Backend ተመርጠው የተሰጠው grade በእውነት እንዳለ ያረጋግጣል።

**ፈቃድ/Permissions**
- Admin-only UI.
- Backend ጥበቃ:
  - `admin-create-user`: **servant ወይም admin** ይፈቀዳል (Admin Portal በ admin ይጠቀማል)፣ grade ያረጋግጣል፣ academic ID እንዳይደጋገም ይጠብቃል።
  - `admin-reset-password`: admin-only.
  - `admin-set-account-status`: admin-only.

---

### 6.2) ተመራቂዎች (Graduates)

**ዓላማ**
- ተመራቂ ተማሪዎችን ብቻ ማሳየት (read-only)።

**የሚታየው**
- `profiles.role = 'student'` እና `account_status = 'graduated'` ያሉ ተማሪዎች።
- መፈለጊያ: በስም፣ academic ID ወይም internal user id.

**እርምጃዎች**
- የለም (read-only)።

**ፈቃድ/Permissions**
- Admin-only UI.

---

### 6.3) አገልጋዮች (Servants)

**ዓላማ**
- የአገልጋይ አካውንቶችን ማየት
- አገልጋይ አካውንቶችን ማንቃት/ማቋረጥ

**የሚታየው**
- `profiles.role = 'servant'` ያሉ መገለጫዎች
- ስም፣ academic ID፣ grade (ካለ) እና status

**እርምጃ**
- **Deactivate / Activate**
  - `account_status` እንደ `inactive_pending_admin` ወይም `active` ይቀየራል
  - confirm ይጠየቃል

**ማረጋገጫ/Validation**
- ቅጽ መስኮች የሉም፤ ድርጊቱ ሁኔታ መቀየር ብቻ ነው።

**ፈቃድ/Permissions**
- Admin-only UI.
- Backend ጥበቃ: `admin-set-account-status` (admin-only) ይጠቀማል።

---

### 6.4) ደረጃዎች (Grades)

**ዓላማ**
- በስርዓቱ ላይ የሚጠቀሙትን ደረጃዎች (Grades) መዋቅር ማዘጋጀት እና ማስተካከል።

**አዲስ ደረጃ መፍጠር: መስኮች**
- **Name** (UI ላይ አስፈላጊ)
- **Code** (በጣም ይመከራል)
- **Sort order** (በጣም ይመከራል)

**አስፈላጊ የDB ገደቦች**
- አሁኑ ስኪማ መሠረት፣ `code` እና `sort_order` **አስፈላጊ (NOT NULL)** ናቸው እና **unique** መሆን አለባቸው።
- UI ላይ “required” በቀጥታ ላይገለጽ ይችላል፣ ግን DB የማይፈቅድ ነገር ሲሆን insert/update ይከለክላል።

**እርምጃዎች**
- **Create** አዲስ grade
- **Save** ነባር grade ላይ ማሻሻል (inline)

**ማረጋገጫ/Validation እና ምክር**
- `code` እና `sort_order` መሞላት አስፈላጊ ነው።
- `sort_order` ፕሮሞሽን ላይ “ቀጣይ ደረጃ” ለመወሰን ይጠቅማል።

**ፈቃድ/Permissions**
- Admin-only UI.

---

### 6.5) ትምህርቶች (Subjects)

**ዓላማ**
- ትምህርቶችን መፍጠር እና ማስተካከል
- ትምህርቱን ከተለያዩ ደረጃዎች (grades) ጋር ማስተያየት
- passing grade እና weight ማቀናበር
- ለእያንዳንዱ ትምህርት **አንድ** prerequisite ማቀናበር (UI በዚህ መጠን ይደግፋል)

**የሚታየው**
- ሁሉም subjects (`subjects` table)
- በ grade ማጣሪያ (optional)
- ለእያንዳንዱ subject: grade, prerequisite, prerequisite minimum score, passing grade, weight

**Subject መፍጠር: መስኮች**
- **Name** (አስፈላጊ)
- **Grade** (መምረጥ ይገባል; DB እስከሚያስፈልገው ድረስ `grade_id` አስፈላጊ ሊሆን ይችላል)
- **Passing grade** (አስፈላጊ; ቁጥር)
- **Weight**
  - ስኪማ መሠረት በብዙ ሁኔታዎች default `0` አለው፣ ግን በ UI ባዶ ካተዉ እና error ካጋጠማችሁ እንደ `0` መሞላት ይመከራል።
- **“Is prerequisite” checkbox**
  - አሁን ባለው UI ውስጥ መረጃ ብቻ ነው (prerequisite link በራሱ አይፈጥርም)።

**Subject ማሻሻል (inline)**
- name, grade, passing grade, weight ማሻሻል
- prerequisite እና minimum score ማሻሻል

**Prerequisites ባህሪ (አስፈላጊ)**
- prerequisite ከ **ተመሳሳይ grade** ውስጥ ካሉ subjects ብቻ ማምረጥ ይችላሉ።
- **Save** ሲጫኑ፣ UI የሚያደርገው፦
  - ቀድሞ የነበሩ prerequisite rows ለዚያ subject ይሰርዛል
  - ከዚያ የተመረጠውን prerequisite (ካለ) ይጨምራል
- ስለዚህ በ UI ደረጃ **ለእያንዳንዱ subject አንድ prerequisite** ብቻ ይገኛል (DB ብዙ prerequisite ሊይዝ ቢችልም)።

**Subject ማጥፋት (Delete)**
- confirm ይጠየቃል።
- ከሌሎች ሰንጠረዦች ጋር በ foreign key ከተያያዘ (assessments, attendance, promotion criteria, prerequisites ወዘተ) ሊከለክል ይችላል።

**Validation & ምክር**
- passing grade ትክክለኛ ቁጥር መሆን አለበት።
- grade ባዶ መተው አይመከርም (DB ሊከለክል ይችላል)።

**ፈቃድ/Permissions**
- Admin-only UI.

---

### 6.6) የትምህርት ዓመት (Academic Year)

**ዓላማ**
- የትምህርት ዓመት እና ሴሚስተር ሽግግር ማስተዳደር።

**የሚያስችለው**
- አሁን ንቁ የሆነ ዓመት ማየት
- Semester 1 መጨረሻ መመዝገብ (`semester1_end_date`)
- Semester 2 መጀመሪያ መመዝገብ (`semester2_start_date`)
- current period መቀየር (`semester1`, `semester2`, `break`)
- ንቁ ዓመት መጨረስ
- አዲስ ዓመት መጀመር
- የተጨረሰ ዓመት ማህደር (archive) ማድረግ (አጥፊ/Destructive)

**Current status ክፍል**
- Active year ስም
- Semester 1 end date + **End Semester 1**
- Semester 2 start date + **Start Semester 2**
- Current period dropdown + **Update Period**
- **End Active Year**

**Semester ሽግግር ገደቦች (backend-enforced)**
- Semester 2 ከመጀመር በፊት Semester 1 መጨረስ ያስፈልጋል።
- Semester 2 መጀመሪያ ቀን ከ Semester 1 መጨረሻ ቀን በፊት መሆን አይችልም።

**አዲስ ዓመት መጀመር (RPC: `start_new_academic_year`)**
- መስኮች:
  - Name (አስፈላጊ)
  - Start date (አስፈላጊ)
  - End date (አስፈላጊ)

**አስፈላጊ ህግ: ፕሮሞሽን ካልተሰራ አዲስ ዓመት መጀመር አይቻልም**
- ቀድሞ ንቁ ዓመት ካለ፣ በዚያ ዓመት **ለሁሉም ደረጃዎች** ፕሮሞሽን መሄድ አለበት፤ ያ ካልሆነ መጀመር ይከለክላል።

**“Start new academic year” ሲጫኑ የሚሆነው (አስፈላጊ)**
- ቀድሞ ንቁ ዓመት ካለ በራሱ ያበቃዋል (end)።
- አዲሱን ዓመት `active` በመሆን ይፈጥራል እና `current_period = 'semester1'` ይሆናል።
- ተማሪዎችን በቀድሞው ዓመት የመጨረሻ የፕሮሞሽን ውጤት መሠረት ያዘምናል፦
  - `eligible` + ቀጣይ ደረጃ ካለ → ወደ ቀጣይ ደረጃ ያስተላልፋል እና `active` ይቆያል
  - `eligible` + ቀጣይ ደረጃ ካልተገኘ → `graduated` ይሆናል
  - ሌላ ሁሉ → ያለው `account_status` እንደነበር ይቀጥላል (active ከሆነ እንደ active ይቀጥላል)

**ንቁ ዓመት መጨረስ (RPC: `end_academic_year`)**
- ዓመቱን `ended` ያደርጋል እና `current_period = 'break'` ይሆናል።
- ውሂብ አያጠፋም (archive አይደለም)።

**የተጨረሰ ዓመት ማህደር ማድረግ (RPC: `archive_academic_year`)**
- UI ላይ በ `ended` ያሉ ዓመታት ላይ ብቻ ይቻላል።
- የዓመቱን ውሂብ ወደ `archive_*` ሰንጠረዦች በመቅዳት ከዚያ ከ live tables ይሰርዛዋል።
- ከዚያ ዓመቱን `archived` ያደርጋል።

**ፈቃድ/Permissions**
- Admin-only UI.
- Backend ጥበቃ: እነዚህ RPC ሁሉ admin-only ናቸው።

---

### 6.7) ፕሮሞሽን (Promotions)

**ዓላማ**
- ለእያንዳንዱ grade የፕሮሞሽን መመዘኛ (criteria) ማቀናበር
- ለሁሉም grades ፕሮሞሽን ማስኬድ እና ማጠቃለያ ውጤት ማየት

**ዋና ነጥብ**
- አዲስ ዓመት ከመጀመር በፊት ፕሮሞሽን መሄድ አስፈላጊ ነው (ቀድሞ ንቁ ዓመት ካለ)።

#### የፕሮሞሽን መመዘኛ (Promotion criteria)

**ወሰን/Scope**
- ፖርታሉ በነባሪ ንቁ ዓመትን (active year) ይይዛል።
- መመዘኛ በ grade መምረጫ ይቀየራል።

**መስኮች**
- **Minimum overall average** (ቁጥር; default 70)
- ለእያንዳንዱ subject በዚያ grade:
  - **Minimum grade** (አስፈላጊ)
  - **Minimum present days** (አስፈላጊ)

**Subjects fallback ማስጠንቀቂያ**
- በተመረጠው grade ላይ subjects ካልነበሩ፣ UI ከሌሎች grades ውስጥ ያሉ subjects ሊያሳይ ይችላል እና ማስጠንቀቂያ ያሳያል።
- ምርጥ ልምድ፦ ለእያንዳንዱ grade ትክክለኛ የሆኑ subjects እንዲኖሩ አስቀድሞ ያዘጋጁ።

**Save Criteria እርምጃ**
- `promotion_criteria_sets` እና `promotion_criteria_subjects` ይፈጥራ/ያዘምናል (upsert)።

**Validation**
- ከዚህ መካከል ካለ ማስቀመጥ አይቻልም፦
  - grade ካልተመረጠ
  - subjects ካልነበሩ
  - ማንኛውም subject ላይ minimum grade ወይም minimum present days ካልተሞሉ

#### ፕሮሞሽን ማስኬድ (Run promotions)

**Run እርምጃ**
- **Run Promotion** ይጫኑ
- የሚጠራው RPC (admin-only)፦ `run_promotion_for_all_grades_with_summary(p_academic_year_id, p_notes)`

**Notes መስክ**
- የሚፈልጉትን ማስታወሻ መጻፍ ይችላሉ።
- ፖርታሉ በተጨማሪ ትንሽ JSON config ያካትታል (traceability ለማድረግ)።

**የውጤት ማጠቃለያ**
- በሁሉም grades ላይ የተሰሩ ጥምር ቁጥሮች (total, eligible, at risk, not eligible, graduated)
- በእያንዳንዱ grade ላይ የተሰሩ ውጤቶች እና `run_id`

**ፈቃድ/Permissions**
- Admin-only UI.
- Backend ጥበቃ: የፕሮሞሽን RPC ሁሉ admin-only ናቸው።

---

### 6.8) ማስታወቂያዎች (Announcements)

**ዓላማ**
- ማስታወቂያ መፍጠር
- ማስታወቂያ ሲፈጠር በአማራጭ push notification መላክ
- ማስታወቂያ ማጥፋት

**ማስታወቂያ መፍጠር: መስኮች**
- **Title** (አስፈላጊ)
- **Message** (አስፈላጊ)
- **Grade (አማራጭ)**
  - ባዶ ከተተወ → global (ለሁሉም grades)
  - ከተመረጠ → ለአንድ grade ብቻ
- **Category** (general / grades / schedule / event / urgent)
- **Priority** (ነፃ ጽሑፍ; default `medium`)
- **Expires on** (አማራጭ)
  - ቀኑ ካልታወቀ (parse ካልቻለ) እንደ ባዶ ይቆጠራል
- **Academic year** (select)
  - በነባሪ ንቁ ዓመትን ይመርጣል
  - ሌላ ዓመት መምረጥ ወይም ባዶ መተው ይቻላል
- **Active** (checkbox)

**Create እርምጃ**
1) ማስታወቂያውን በ DB ይመዝግባል
2) ከዚያ በኋላ `push-notify` Edge Function በመጠቀም push notification ለመላክ ይሞክራል

**Push notifications እጅግ አማራጭ (best-effort) ናቸው**
- push ካልተላከ (ወይም ተቀባዮች/ቶከኖች ካልነበሩ) ፖርታሉ መልዕክት (notice) ያሳያል።
- ማስታወቂያው ግን እንኳን push ቢሳካ/ቢከለክል ተቀምጦ ይኖራል።

**Delete እርምጃ**
- confirm ካደረጉ በኋላ ማስታወቂያውን ይሰርዛል።

**ፈቃድ/Permissions**
- Admin-only UI.

---

## 7) የሥራ ፍሰቶች (Workflows)

### 7.1) አዲስ ስርዓት ማዘጋጀት (Set up a new system)

የሚመከረው ቅደም ተከተል፦
1) **Grades**: name, code, sort order ትክክል መሆናቸውን ያረጋግጡ
2) **Subjects**: ለእያንዳንዱ grade subjects ይፍጠሩ
3) **Subjects**: prerequisites ካሉ ያቀናብሩ
4) **Academic Year**: አዲስ ዓመት ይጀምሩ
5) **Promotions**: ለሁሉም grades criteria ያቀናብሩ (አስቀድሞ ማድረግ ይመከራል)

---

### 7.2) አዲስ ተማሪ ማስመዝገብ (Onboard a new student)

1) **Students** ይግቡ
2) **Name** ይሙሉ እና **Grade** ይምረጡ
3) አማራጭ:
   - Academic ID: ካለዎት ያስገቡ፤ ካልሆነ ባዶ ተዉ እንዲመደብ
   - Password: ባዶ ቢተዉ በ academic ID ይሆናል
   - Email: አማራጭ
4) **Create** ይጫኑ
5) academic ID በ alert ከታየ፣ ይመዝግቡ

---

### 7.3) የተማሪ የይለፍ ቃል ማስጀመር (Reset a student password)

1) **Students** ይግቡ
2) ተማሪውን ያግኙ
3) **Reset Password** ይጫኑ
4) አዲሱን የይለፍ ቃል ያስገቡ
5) የይለፍ ቃሉን በደህንነት ያስተላልፉ

---

### 7.4) አካውንት ማንቃት/ማቋረጥ (Activate / deactivate accounts)

**ተማሪዎች**
- Students → **Deactivate** ወይም **Activate**

**አገልጋዮች**
- Servants → **Deactivate** ወይም **Activate**

ማስታወሻ:
- የተቋረጡ አካውንቶች `inactive_pending_admin` ይሆናሉ።
- `graduated` ያሉ ተማሪዎች ሁኔታ ለመቀየር አይቻልም (read-only)።

---

### 7.5) የሴሚስተር ሽግግሮች (Semester transitions)

**Semester 1 መጨረስ**
1) Academic Year → Semester 1 end date ያስገቡ
2) **End Semester 1** ይጫኑ

**Semester 2 መጀመር**
1) Academic Year → Semester 2 start date ያስገቡ
2) **Start Semester 2** ይጫኑ

ገደቦች:
- Semester 2 ከመጀመር በፊት Semester 1 መጨረስ አለበት
- Semester 2 ጀማሪ ቀን ከ Semester 1 መጨረሻ በፊት ሊሆን አይችልም

---

### 7.6) የዓመት-መጨረሻ ፕሮሞሽን + አዲስ ዓመት መጀመር

1) Promotions → ለሁሉም grades criteria እንደተቀመጠ ያረጋግጡ
2) Promotions → **Run Promotion** ይጫኑ
3) ማጠቃለያውን ይመልከቱ
4) Academic Year → አዲስ ዓመት ይጀምሩ
   - በቀድሞ ንቁ ዓመት ላይ ለማንኛውም grade ፕሮሞሽን ካልተሰራ ይከለክላል እና የጎደሉትን grades ይዘርዝራል

---

### 7.7) የተጨረሰ ዓመት ማህደር ማድረግ (Archive — አጥፊ)

1) Academic Year → `ended` ያለ ዓመት ይምረጡ
2) **Archive** ይጫኑ
3) confirm

ማስጠንቀቂያ:
- ይህ እርምጃ አጥፊ (destructive) ነው፤ የዓመቱን ውሂብ ወደ archive tables ካቀመጠ በኋላ ከ live tables ይሰርዛል።

---

### 7.8) ማስታወቂያ ማቅረብ + push notification

1) Announcements → title እና message ይሙሉ
2) አማራጭ:
   - grade መምረጥ (የተወሰነ grade ለመድረስ)
   - category, priority, expiry, academic year ማቀናበር
3) **Create** ይጫኑ
4) push ስለ መላክ መልዕክት ካታየ፣ ማስታወቂያው ተቀምጦ ነው ነገር ግን push አልተላከም (ወይም 0 ላክ) ማለት ነው

---

## 8) ምርጥ ልምዶች (Best practices)

- grade ላይ `code` እና `sort_order` እንደ **አስፈላጊ** ይመልከቱ እና unique ያድርጉ
- ለእያንዳንዱ subject ትክክለኛ grade ይመድቡ (criteria ከዚህ ጋር ይተያያዛል)
- የፕሮሞሽን criteria ቀድሞ ያቀናብሩ
- አዲስ ዓመት ከመጀመር በፊት ለሁሉም grades ፕሮሞሽን አስኪዱ እና ማጠቃለያውን ያረጋግጡ
- deactivation ሲደረግ ተጠቃሚው በፖሊሲ/RLS ሊከለክል ስለሚችል ተጠንቀቁ
- ማስታወቂያዎች ሁሉን ካልመለከቱ በ grade ለማጥናት ይመከራል
- subjects መሰረዝ ከመድረስ በፊት ተያያዥ ውሂቦች መኖራቸውን ያረጋግጡ
- archive ከመድረስ በፊት “በእውነት ይህ ዓመት ቀጥታ እንዳይኖር ተወስኗል?” ብለው ያረጋግጡ

---

## 9) ተጠንቀቁ የሚገባቸው እርምጃዎች እና ማስጠንቀቂያዎች

- **Archive Academic Year**: አጥፊ ነው፤ የዓመቱን live data ከ archive በኋላ ይሰርዛል
- **Start New Academic Year**: ቀድሞውን ዓመት ያበቃዋል እና ብዙ ተማሪ መረጃ (grade/status) ያዘምናል
- **Run Promotions**: promotion runs/results ይፈጥራል እና ተማሪዎችን `graduated` ሊያደርግ ይችላል
- **Reset Password**: ወዲያውኑ የመግቢያ ብቃት ይቀየራል
- **Deactivate Account**: ተጠቃሚ ማግኘት/መጠቀም ሊከለክል ይችላል
- **Delete Subject**: በ foreign key የተገናኘ ከሆነ ሊከለክል ይችላል እና ታሪካዊ መረጃዎችን ሊያበላሽ ይችላል

---

## 10) የውሂብ ሞዴል (admin-ተገቢ)

ይህ ክፍል በ Admin Portal በብዛት የሚጠቀሙባቸውን ሰንጠረዦች በቀላሉ ይገልጻል።

### መለያ/Identity
- `profiles`
  - ለእያንዳንዱ user አንድ row (ከ `auth.users` ጋር ይጣመራል)
  - ዋና መስኮች: `id`, `role (admin/student/servant)`, `academic_id`, `name`, `grade_id`, `account_status (active/inactive_pending_admin/graduated)`

### መዋቅር/Structure
- `grades`: `id`, `name`, `code`, `sort_order`
- `subjects`: `id`, `grade_id`, `name`, `passing_grade`, `weight`, `active`
- `subject_prerequisites`: `subject_id`, `prerequisite_subject_id`, `minimum_score`

### የትምህርት ዓመት
- `academic_years`
  - `id`, `name`, `start_date`, `end_date`, `status (active/ended/archived)`,
    `current_period (semester1/semester2/break)`, `semester1_end_date`, `semester2_start_date`, `ended_at`, `archived_at`

### ማስታወቂያ
- `announcements`
  - `id`, `academic_year_id (optional)`, `grade_id (optional)`, `title`, `message`, `category`, `priority`, `active`, `expires_on`, `created_by`

### ፕሮሞሽን
- `promotion_criteria_sets`: ለ `(academic_year_id, grade_id)` አንድ criteria
- `promotion_criteria_subjects`: ለ criteria set የእያንዳንዱ subject መመዘኛ
- `promotion_runs`: ፕሮሞሽን የተሰራበት መረጃ (ዓመት + grade + ጊዜ + notes)
- `promotion_results`: ለእያንዳንዱ ተማሪ የተመዘነ ውጤት (status/averages/next grade…)

### Archive tables
- `archive_*` ሰንጠረዦች በ `archive_academic_year` RPC ይጠቀሙባቸዋል
- የዓመቱን ታሪካዊ ውሂብ ለማቆየት እና live tables ለማጽዳት ይረዳሉ

---

## 11) ስህተት አስተዳደር እና መፍትሄ መፈለጊያ (Troubleshooting)

### ስህተት እንዴት ይታያል?
- ብዙ ገጾች ላይ **ErrorBanner** ይታያል።
- አንዳንድ የተለመዱ ስህተቶች በ UI ደረጃ “humanize” ይደረጋሉ:
  - network fetch ችግኝ → “Network error”
  - “Invalid login credentials” → የመግቢያ ስህተት
  - “Email not confirmed” → ኢሜይል አልተረጋገጠም

### የተለመዱ ችግኝና መፍትሄዎች

**“Access denied / not admin”**
- ምክንያት: `profiles.role` እንደ `admin` አይደለም
- ውጤት: sign out ይደርሳል እና `/sign-in` ይመለሳሉ

**Network errors / failed to fetch**
- ምክንያት: ኢንተርኔት ችግኝ፣ የSupabase URL ችግኝ፣ መከልከል (blocked requests)
- መፍትሄ: ኢንተርኔትን ያረጋግጡ፣ Supabase URL እና Edge Functions endpoint ይፈትሹ

**Grades/Subjects create/save ሲሳነ**
- ምክንያት: DB constraints (required/unique) በ UI ላይ ቢታይም
- መፍትሄ:
  - Grades: `code` እና `sort_order` ይሙሉ እና unique መሆናቸውን ያረጋግጡ
  - Subjects: grade ይምረጡ እና passing grade ቁጥር መሆኑን ያረጋግጡ (weight ላይ error ካለ እንደ `0` ይሙሉ)

**Subject delete blocked**
- ምክንያት: foreign key references
- መፍትሄ: ተያያዥ መረጃዎችን ቀድሞ ያስወግዱ (assessments, attendance, criteria, prerequisites…)

**Announcement push notice**
- ምክንያት: push በ best-effort ነው፤ recipients/tokens ሊጎዱ ይችላሉ ወይም FCM አልተዘጋጀም
- መፍትሄ: ማስታወቂያው ተቀምጦ ነው ብለው ይቀጥሉ፤ push config በተለይ ይመርምሩ

---

## 12) የዲቨሎፐር ማስታወሻ (Developer notes — አማራጭ)

### የEdge Function የመለያ ራስጌዎች (Auth headers)

ይህ ፕሮጀክት ሲጠራ Edge Functions የሚጠቀምበት የgateway-safe pattern፦
- `apikey: <SUPABASE_ANON_KEY>`
- `Authorization: Bearer <SUPABASE_ANON_KEY>`
- `X-Authorization: Bearer <USER_JWT_ACCESS_TOKEN>`

Edge Functions ውስጥ `X-Authorization` በመጀመሪያ እንዲነበብ ተዘጋጅቷል።

### Admin Portal የሚፈልጉ የአካባቢ ተለዋዋጮች (env vars)
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

### Push notifications (server-side)
- `push-notify` Edge Function ለ Firebase/FCM ምስጢሮች (legacy server key ወይም service account JSON) እና Supabase service role key ይፈልጋል።
