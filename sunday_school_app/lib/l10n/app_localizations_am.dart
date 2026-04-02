// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'DEAS EMSS';

  @override
  String get roleSelectionTitle => 'እግዚአብሔር ምስሌነ';

  @override
  String get roleSelectionSubtitle => 'የተከታታይ ትምህርት ዲጂታል አስተዳደር ሥርዓት';

  @override
  String get roleStudent => 'ተማሪ';

  @override
  String get roleStudentSubtitle => 'ውጤት፣ መገኘት እና ግንኙነት ይመልከቱ';

  @override
  String get roleServant => 'አገልጋይ';

  @override
  String get roleServantSubtitle => 'ክፍል፣ ውጤት እና መገኘት ያስተዳድሩ';

  @override
  String get roleSelectPrompt => 'ለመቀጠል ሚናዎን ይምረጡ';

  @override
  String get navHome => 'መነሻ';

  @override
  String get navAttendance => 'መገኘት';

  @override
  String get navGrades => 'ውጤት';

  @override
  String get navCommunication => 'ግንኙነት';

  @override
  String get navProfile => 'መገለጫ';

  @override
  String get commonBackToHome => 'ወደ መነሻ ገጽ';

  @override
  String get commonRetry => 'እንደገና ሞክር';

  @override
  String get commonSearch => 'ፈልግ';

  @override
  String get commonSave => 'አስቀምጥ';

  @override
  String get commonSend => 'ላክ';

  @override
  String get commonSubmit => 'አስገባ';

  @override
  String get commonOk => 'እሺ';

  @override
  String get commonCancel => 'ሰርዝ';

  @override
  String get commonDelete => 'አጥፋ';

  @override
  String get commonHigh => 'ከፍተኛ';

  @override
  String get commonMedium => 'መካከለኛ';

  @override
  String get commonLow => 'ዝቅተኛ';

  @override
  String get commonAll => 'ሁሉም';

  @override
  String get commonStatus => 'ሁኔታ';

  @override
  String get commonUpdate => 'አዘምን';

  @override
  String get commonTryChangingFilters => 'ማጣሪያዎቹን በመቀየር ይሞክሩ።';

  @override
  String get commonBack => 'ወደ ኋላ';

  @override
  String get commonPrev => 'ቀዳሚ';

  @override
  String get commonNext => 'ቀጣይ';

  @override
  String get commonPending => 'በመጠባበቅ ላይ';

  @override
  String commonQuestionShort(Object number) {
    return 'ጥ$number';
  }

  @override
  String get commonDate => 'ቀን';

  @override
  String get commonYou => 'እርስዎ';

  @override
  String get commonAddDate => 'ቀን ጨምር';

  @override
  String get commonNa => 'አይመለከትም';

  @override
  String get commonNoSubjectsForGrade => 'ለክፍልዎ ትምህርቶች አልተገኙም።';

  @override
  String commonWarningMessage(Object message) {
    return '⚠️ $message';
  }

  @override
  String get commonSignOut => 'ውጣ';

  @override
  String get profileAccountDetailsSubtitle => 'የመለያ ዝርዝሮች';

  @override
  String get profileLoadFailedTitle => 'መገለጫውን መጫን አልተሳካም';

  @override
  String get profileNotAssigned => 'አልተመደበም';

  @override
  String get profileAcademicIdLabel => 'ትምህርታዊ መለያ';

  @override
  String get profileGradeLabel => 'ክፍል';

  @override
  String get profileAccountStatusLabel => 'የመለያ ሁኔታ';

  @override
  String get profileRoleLabel => 'ሚና';

  @override
  String get profileChangePassword => 'የይለፍ ቃል ቀይር';

  @override
  String get profileChangePasswordSubtitle => 'ለመለያዎ አዲስ የይለፍ ቃል ያስገቡ';

  @override
  String get accountStatusActive => 'በሥራ ላይ';

  @override
  String get accountStatusInactive => 'የማይሠራ';

  @override
  String get accountStatusSuspended => 'ታግዷል';

  @override
  String get accountStatusDisabled => 'ተሰናክሏል';

  @override
  String get servantGradesDeleteAssessmentTitle => 'ምዘና ይሰረዝ?';

  @override
  String servantGradesDeleteAssessmentBody(Object name) {
    return '\"$name\" ይሰረዝ? ይህ መመለስ አይቻልም።';
  }

  @override
  String get servantGradesDeleteAssessmentFailed => 'ምዘናውን መሰረዝ አልተሳካም።';

  @override
  String get servantGradesFillRequiredFieldsError => 'እባክዎ አስፈላጊ መስኮችን ሁሉ ይሙሉ።';

  @override
  String get servantGradesWeightRangeError => 'ክብደት በ0 እና 100 መካከል መሆን አለበት።';

  @override
  String servantGradesInvalidScore(Object maxScore, Object student) {
    return 'ለ$student የገባው ውጤት ልክ አይደለም። 0-$maxScore መሆን አለበት።';
  }

  @override
  String get servantGradesAssessmentUpdated => 'ምዘናው ተዘምኗል።';

  @override
  String get servantGradesAssessmentAdded => 'ምዘና ተጨምሯል።';

  @override
  String get servantGradesSaveAssessmentFailed => 'ምዘናውን ማስቀመጥ አልተሳካም።';

  @override
  String get servantGradesSubjectNameRequired => 'የትምህርት ስም ያስፈልጋል።';

  @override
  String get servantGradesSubjectAdded => 'ትምህርት ተጨምሯል።';

  @override
  String get servantGradesSubjectAddFailed => 'ትምህርት ማከል አልተሳካም።';

  @override
  String get servantGradesAddNewAssessment => 'አዲስ ምዘና ጨምር';

  @override
  String get servantGradesHideGrades => 'ውጤቶችን ደብቅ';

  @override
  String get servantGradesAllGrades => 'ሁሉም ውጤቶች';

  @override
  String get servantGradesMissing => 'ያልተሞላ';

  @override
  String get servantGradesTotalWeightLabel => 'ጠቅላላ ክብደት:';

  @override
  String get servantGradesTotalWeightExceeds => 'ጠቅላላ ክብደት 100% በላይ ነው';

  @override
  String servantGradesRemainingToReach100(Object remaining) {
    return '100% ለማድረስ $remaining% ቀርቷል';
  }

  @override
  String get servantGradesAddAssessmentTitle => 'ምዘና ጨምር';

  @override
  String get servantGradesEditAssessmentTitle => 'ምዘና አስተካክል';

  @override
  String servantGradesClassAvgLabel(Object percent) {
    return 'የክፍል አማካኝ: $percent%';
  }

  @override
  String get servantGradesStudentScoresOptional => 'የተማሪ ውጤቶች (አማራጭ)';

  @override
  String get servantGradesSearchStudentsHint => 'ተማሪዎችን ፈልግ...';

  @override
  String servantGradesPageLabel(Object current, Object total) {
    return 'ገጽ $current / $total';
  }

  @override
  String get servantGradesScoreHint => 'ውጤት';

  @override
  String get servantGradesAddSubjectTitle => 'ትምህርት ጨምር';

  @override
  String get servantGradesSubjectNameHint => 'የትምህርት ስም (ለምሳሌ፦ ስነ መለኮት)';

  @override
  String get servantGradesManageTitle => 'ውጤቶችን አስተዳድር';

  @override
  String get servantGradesNewSubjectChip => 'አዲስ ትምህርት';

  @override
  String servantGradesWeightedTitle(Object subjectName) {
    return 'የተማሪ ክብደታዊ ውጤት - $subjectName';
  }

  @override
  String servantGradesWeightedBasedOn(num count, Object totalWeight) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'በ$count ምዘናዎች ላይ ተመስርቶ፣ ጠቅላላ ክብደት $totalWeight%',
      one: 'በ1 ምዘና ላይ ተመስርቶ፣ ጠቅላላ ክብደት $totalWeight%',
    );
    return '$_temp0';
  }

  @override
  String get servantGradesWeightedSearchByStudentNameHint => 'በተማሪ ስም ፈልግ...';

  @override
  String get servantGradesWeightedStudentNameHeader => 'የተማሪ ስም';

  @override
  String get servantGradesWeightedScoreHeader => 'ክብደታዊ ውጤት';

  @override
  String get servantGradesWeightedGradeHeader => 'ደረጃ';

  @override
  String get servantGradesWeightedClassAverageLabel => 'የክፍል አማካኝ';

  @override
  String get servantGradesWeightedHighestLabel => 'ከፍተኛ';

  @override
  String get servantGradesWeightedLowestLabel => 'ዝቅተኛ';

  @override
  String get servantGradesMissingLabel => 'ያልተሞላ:';

  @override
  String get servantGradesIncomplete => 'ያልተሟላ';

  @override
  String servantGradesMissingCount(Object count) {
    return '$count ያልተሞላ';
  }

  @override
  String servantGradesMaxPoints(Object maxScore) {
    return 'ከፍተኛ: $maxScore ነጥብ';
  }

  @override
  String get servantGradesEditGradesTooltip => 'ውጤቶችን አስተካክል';

  @override
  String get servantGradesDeleteAssessmentTooltip => 'ምዘና ሰርዝ';

  @override
  String get servantGradesClassAverageLabel => 'የክፍል አማካኝ';

  @override
  String get servantGradesHideStudentScores => 'የተማሪ ውጤቶችን ደብቅ';

  @override
  String get servantGradesViewStudentScores => 'የተማሪ ውጤቶችን አሳይ';

  @override
  String get servantGradesNoAssessmentsYetTitle => 'እስካሁን ምዘና የለም';

  @override
  String get servantGradesNoAssessmentsYetBody =>
      'ለዚህ ትምህርት የተማሪ ውጤቶችን ለመከታተል ምዘና ያክሉ።';

  @override
  String get servantGradesAssessmentNameHint => 'የምዘና ስም (ለምሳሌ፦ ኩዊዝ 1)';

  @override
  String get servantGradesMaxScoreHint => 'ከፍተኛ ነጥብ';

  @override
  String get servantGradesWeightPercentOptionalHint => 'ክብደት % (አማራጭ)';

  @override
  String get authStudentLoginTitle => 'የተማሪ መግቢያ';

  @override
  String get authServantLoginTitle => 'የአገልጋይ መግቢያ';

  @override
  String get authLoginSubtitle => 'ለመቀጠል የመለያ መረጃዎን ያስገቡ';

  @override
  String get authEmailLabel => 'መለያ';

  @override
  String get authPasswordLabel => 'የይለፍ ቃል';

  @override
  String get authEmailHint => 'መለያዎን ያስገቡ';

  @override
  String get authPasswordHint => 'የይለፍ ቃልዎን ያስገቡ';

  @override
  String get authNewPasswordLabel => 'አዲስ የይለፍ ቃል';

  @override
  String get authNewPasswordHint => 'አዲስ የይለፍ ቃል ያስገቡ';

  @override
  String get authConfirmPasswordLabel => 'የይለፍ ቃል አረጋግጥ';

  @override
  String get authConfirmPasswordHint => 'አዲሱን የይለፍ ቃል እንደገና ያስገቡ';

  @override
  String get authEmailRequiredError => 'እባክዎ ኢሜይልዎን ያስገቡ';

  @override
  String get authPasswordRequiredError => 'እባክዎ የይለፍ ቃልዎን ያስገቡ';

  @override
  String get authConfirmPasswordRequiredError => 'እባክዎ የይለፍ ቃልዎን ያረጋግጡ';

  @override
  String get authPasswordMismatchError => 'የይለፍ ቃሎቹ አይዛመዱም';

  @override
  String authPasswordMinLengthError(Object min) {
    return 'የይለፍ ቃል ቢያንስ $min ፊደሎች መሆን አለበት';
  }

  @override
  String get authLoginButton => 'ግባ';

  @override
  String get authForgotPassword => 'የይለፍ ቃል ረስተዋል?';

  @override
  String get authForgotPasswordDialogTitle => 'የይለፍ ቃል መቀየር';

  @override
  String get authForgotPasswordDialogBody =>
      'የይለፍ ቃል ለመቀየር እባክዎ \"የተከታታይ ትምህርት ክፍል ኃላፊ\"ን ያነጋግሩ።';

  @override
  String get authDemoMode =>
      'ሙከራ (Demo): ማንኛውንም ትክክለኛ ኢሜይል እና የይለፍ ቃል ይጠቀሙ\nጀርባ ስርዓቱ እስከሚጠናቀቅ ድረስ።';

  @override
  String get authLoginFailedGeneric => 'መግባት አልተሳካም። እባክዎ በድጋሚ ይሞክሩ።';

  @override
  String get authRoleMismatchStudent =>
      'ይህ መለያ የተማሪ መለያ አይደለም። ለመቀጠል የአገልጋይ ሚና ይምረጡ።';

  @override
  String get authRoleMismatchServant =>
      'ይህ መለያ የአገልጋይ መለያ አይደለም። ለመቀጠል የተማሪ ሚና ይምረጡ።';

  @override
  String get authRoleVerificationFailed =>
      'የመለያዎን ሚና ማረጋገጥ አልተቻለም። እባክዎ በድጋሚ ይሞክሩ።';

  @override
  String get authPasswordUpdateSuccess => 'የይለፍ ቃል ተዘምኗል።';

  @override
  String get authPasswordUpdateFailedGeneric =>
      'የይለፍ ቃል ማዘመን አልተሳካም። እባክዎ በድጋሚ ይሞክሩ።';

  @override
  String get dashboardWelcome => 'እንኳን በደህና መጡ!';

  @override
  String get dashboardAttendanceStat => 'የመገኘት መቆጣጠሪያ';

  @override
  String get dashboardAverageScoreStat => 'አማካኝ ውጤት';

  @override
  String get dashboardCommunicationTitle => 'ግንኙነት';

  @override
  String dashboardPendingCount(Object count) {
    return '$count በመጠባበቅ ላይ';
  }

  @override
  String get dashboardPendingQuestions => 'በመጠባበቅ ላይ ያሉ ጥያቄዎች';

  @override
  String get dashboardOpenComplaints => 'ክፍት ቅሬታዎች';

  @override
  String get dashboardGoToCommunication => 'ወደ ግንኙነት ይሂዱ';

  @override
  String get dashboardQuickActions => 'ፈጣን እርምጃዎች';

  @override
  String get dashboardViewGrades => 'ውጤት ይመልከቱ';

  @override
  String get attendanceTrackSubtitle => 'የክፍል ተሳትፎዎን ይከታተሉ';

  @override
  String get attendanceOverallTitle => 'አጠቃላይ መገኘት';

  @override
  String get attendanceAcrossAllSubjects => 'በሁሉም ትምህርቶች';

  @override
  String attendancePercentLabel(Object percent) {
    return '$percent% መገኘት';
  }

  @override
  String get attendancePresent => 'ተገኝቷል';

  @override
  String get attendanceLate => 'ዘግይቷል';

  @override
  String get attendanceAbsent => 'አልተገኘም';

  @override
  String get attendancePermission => 'በፈቃድ';

  @override
  String get attendancePerformanceExcellent => 'በጣም ጥሩ መገኘት!';

  @override
  String get attendancePerformanceGreat => 'ጥሩ መገኘት!';

  @override
  String get attendancePerformanceGood => 'መልካም መገኘት';

  @override
  String get attendancePerformanceNeedsImprovement => 'መገኘት መሻሻል ያስፈልጋል';

  @override
  String get attendanceHistoryTitle => 'የመገኘት ታሪክ';

  @override
  String attendanceSessionsRecorded(Object count) {
    return '$count ስብሰባ ተመዝግቧል';
  }

  @override
  String get attendanceNoRecordsYet => 'እስካሁን የመገኘት መዝገብ የለም';

  @override
  String get attendanceImproveTitle => 'መገኘትዎን ያሻሽሉ';

  @override
  String get attendanceImproveBody =>
      'መደበኛ መገኘት ለመማርና ለደረጃ ማደግ አስፈላጊ ነው። ሁሉንም ክፍሎች ለመሳተፍ እና በሰዓቱ ለመድረስ ይሞክሩ።';

  @override
  String get servantAttendanceChooseSubjectAndDate => 'ትምህርትና ቀን ይምረጡ';

  @override
  String get servantAttendanceMinimumDaysAbsent => 'አነስተኛ የቀረ ቀናት';

  @override
  String get servantAttendanceMinAbsentHint => 'ቢያንስ የቀሩትን ቀናት ያስገቡ';

  @override
  String servantAttendanceStudentsAbsentAtLeast(Object days) {
    return 'ቢያንስ $days ቀን የቀሩ ተማሪዎች:';
  }

  @override
  String get servantAttendanceNoStudentsMatch => 'ተመሳሳይ ተማሪ አልተገኘም።';

  @override
  String servantAttendanceAbsentDays(Object days) {
    return '$days ቀን ቀርቷል';
  }

  @override
  String get servantAttendancePreviousDates => 'ቀደም ያሉ ቀናት';

  @override
  String get servantAttendanceNoDatesYet => 'እስካሁን የመገኘት ቀናት የሉም።';

  @override
  String get servantAttendanceSearchStudentsHint => 'ተማሪዎችን ፈልግ';

  @override
  String get servantAttendanceSaved => 'መገኘት ተመዝግቧል';

  @override
  String get servantAttendanceSaveFailed => 'መገኘት ማስቀመጥ አልተሳካም';

  @override
  String get commAnnouncements => 'ማስታወቂያዎች';

  @override
  String get commQuestions => 'ጥያቄዎች';

  @override
  String get commComplaints => 'ቅሬታዎች';

  @override
  String get commFeedback => 'አስተያየት';

  @override
  String get servantCommSubtitle => 'ማስታወቂያዎች፣ ጥያቄዎች፣ ቅሬታዎች እና አስተያየት።';

  @override
  String get commNoAnnouncements => 'ማስታወቂያ የለም';

  @override
  String get commAnnouncementsEmptySubtitle => 'ለአዳዲስ መረጃዎች ቆይተው ይመለሱ';

  @override
  String get commAnnouncementsLoadFailed => 'ማስታወቂያዎችን መጫን አልተሳካም።';

  @override
  String get commAnnouncementCategoryUrgent => 'አስቸኳይ';

  @override
  String get commAnnouncementCategoryGrades => 'ውጤቶች';

  @override
  String get commAnnouncementCategorySchedule => 'መርሃ ግብር';

  @override
  String get commAnnouncementCategoryEvent => 'ዝግጅት';

  @override
  String get commAnnouncementCategoryGeneral => 'አጠቃላይ';

  @override
  String commPostedBy(Object name) {
    return 'በ$name ተለጥፏል';
  }

  @override
  String get commAskQuestion => 'ጥያቄ ጠይቅ';

  @override
  String get commPending => 'በመጠባበቅ ላይ';

  @override
  String get commAnswered => 'ተመልሷል';

  @override
  String get commInReview => 'በግምገማ ላይ';

  @override
  String get commResolved => 'ተፈትቷል';

  @override
  String get commNoQuestionsYet => 'እስካሁን ጥያቄ የለም';

  @override
  String get commResponseLabel => 'መልስ:';

  @override
  String get servantCommNoComplaints => 'ምንም ቅሬታ የለም';

  @override
  String get servantCommRespond => 'መልስ ስጥ';

  @override
  String get servantCommTypeResponseHint => 'መልስዎን ይጻፉ...';

  @override
  String get servantCommEnterResponseError => 'እባክዎ መልስ ያስገቡ።';

  @override
  String get servantCommSavedLocallySyncFailed => 'በአካባቢ ተቀምጧል፤ ማስተካከል አልተሳካም።';

  @override
  String get servantCommSendResponse => 'መልስ ላክ';

  @override
  String get servantCommDeleteQuestionTitle => 'ጥያቄውን ማጥፋት?';

  @override
  String get servantCommDeleteQuestionBody => 'ይህ ጥያቄ በቋሚነት ይሰረዛል።';

  @override
  String get servantCommDeleteQuestionPermissionDenied =>
      'ጥያቄዎችን ለማጥፋት ፈቃድ ላይኖርዎ ይችላል።';

  @override
  String get servantCommDeleteComplaintTitle => 'ቅሬታውን ማጥፋት?';

  @override
  String get servantCommDeleteComplaintBody => 'ይህ ቅሬታ በቋሚነት ይሰረዛል።';

  @override
  String get servantCommDeleteFromServerFailed => 'ከሰርቨሩ ላይ ማጥፋት አልተቻለም።';

  @override
  String get commSubjectBibleStudies => 'የመጽሐፍ ቅዱስ ትምህርት';

  @override
  String get commSubjectChristianHistory => 'የክርስትና ታሪክ';

  @override
  String get commSubjectGeneral => 'አጠቃላይ';

  @override
  String get commSubjectLabel => 'ትምህርት';

  @override
  String get commYourQuestionLabel => 'ጥያቄዎ';

  @override
  String get commQuestionHint => 'ጥያቄዎን እዚህ ይጻፉ...';

  @override
  String get commSelectSubjectError => 'እባክዎ ትምህርት ይምረጡ';

  @override
  String get commEnterQuestionError => 'እባክዎ ጥያቄዎን ያስገቡ';

  @override
  String get commQuestionSubmitted => 'ጥያቄው ተላክ!';

  @override
  String get commSubmitComplaint => 'ቅሬታ አቅርብ';

  @override
  String get commNoComplaintsSubmitted => 'እስካሁን ቅሬታ አልተላከም';

  @override
  String get commCategoryLabel => 'ምድብ';

  @override
  String get commCategoryTeacher => 'አስተማሪ';

  @override
  String get commCategoryFacility => 'መገልገያ';

  @override
  String get commCategoryCourse => 'ትምህርት';

  @override
  String get commCategoryAdministrative => 'አስተዳደር';

  @override
  String get commCategoryOther => 'ሌላ';

  @override
  String get commSelectCategoryError => 'እባክዎ ምድብ ይምረጡ';

  @override
  String get commTitleLabel => 'ርዕስ';

  @override
  String get commComplaintTitleHint => 'ለቅሬታዎ አጭር ርዕስ';

  @override
  String get commEnterTitleError => 'እባክዎ ርዕስ ያስገቡ';

  @override
  String get commDescriptionLabel => 'መግለጫ';

  @override
  String get commComplaintDescriptionHint => 'ቅሬታዎን በዝርዝር ይጻፉ...';

  @override
  String get commEnterDescriptionError => 'እባክዎ መግለጫ ያስገቡ';

  @override
  String get commSubmitAnonymously => 'ስም ሳይጠቀስ አቅርብ';

  @override
  String get commComplaintSubmitted => 'ቅሬታው ተላክ!';

  @override
  String get commNoActiveFeedbackForms => 'ንቁ የግብረመልስ ቅጾች የሉም';

  @override
  String get commFeedbackEmptySubtitle =>
      'አገልጋዩ በወደፊት የግብረመልስ ቅጾችን ሊካፈል ይችላል። ከጊዜ በኋላ ይመለሱ።';

  @override
  String get bootstrapErrorTitle => 'መተግበሪያው መጀመር አልቻለም';

  @override
  String get bootstrapErrorFix => 'መፍትሄ: የSupabase ቅንብር ያረጋግጡ';

  @override
  String get bootstrapErrorVerifyPath =>
      'lib/core/config/supabase_config.dart ውስጥ ያሉ እሴቶችን ያረጋግጡ';

  @override
  String get servantDashboardTitle => 'የአገልጋይ ዳሽቦርድ';

  @override
  String get servantDashboardSubtitle => 'የክፍል አስተዳደር';

  @override
  String get servantTotalStudents => 'ጠቅላላ ተማሪዎች';

  @override
  String get servantDashboardAvgAttendanceLabel => 'አማካኝ መገኘት';

  @override
  String get servantDashboardPendingItemsLabel => 'በመጠባበቅ ላይ';

  @override
  String get servantDashboardQuickActionsTitle => 'ፈጣን እርምጃዎች';

  @override
  String get servantDashboardMarkAttendanceTitle => 'መገኘት ምልክት አድርግ';

  @override
  String get servantDashboardMarkAttendanceSubtitle => 'የዛሬን መገኘት መዝግብ';

  @override
  String get servantDashboardAddGradesTitle => 'ውጤት ጨምር';

  @override
  String get servantDashboardAddGradesSubtitle => 'የተማሪ ውጤቶችን አስገባ ወይም አዘምን';

  @override
  String get servantRegisterStudentQuickActionTitle => 'ተማሪ መመዝገብ';

  @override
  String get servantRegisterStudentQuickActionSubtitle => 'አዲስ ተማሪ ወደ ክፍል ጨምር';

  @override
  String get servantRegisterStudentTitle => 'ተማሪ መመዝገብ';

  @override
  String get servantRegisterStudentFullNameLabel => 'የተማሪው ሙሉ ስም';

  @override
  String get servantRegisterStudentFullNameHint => 'ለምሳሌ፡ ዮሐንስ ዶ';

  @override
  String get servantRegisterStudentGradeLabel => 'የሚመዘገብበት ክፍል';

  @override
  String get servantRegisterStudentSubmit => 'መመዝገብ';

  @override
  String get servantRegisterStudentNameRequired => 'የተማሪውን ሙሉ ስም ያስገቡ';

  @override
  String get servantRegisterStudentGradeRequired => 'ክፍል ይምረጡ';

  @override
  String get servantRegisterStudentSuccessTitle => 'ተማሪ ተመዝግቧል';

  @override
  String servantRegisterStudentSuccessMessage(Object academicId) {
    return 'አካዳሚክ መለያ፡ $academicId\nየመጀመሪያ የይለፍ ቃል፡ ከአካዳሚክ መለያው ጋር አንድ ነው';
  }

  @override
  String get servantDashboardGradeAnalyticsSubtitle => 'የአፈጻጸም ግንዛቤ እና አዝማሚያ';

  @override
  String get servantDashboardTodayScheduleTitle => 'የዛሬ መርሃ ግብር';

  @override
  String get servantDashboardSundaySchoolClassTitle => 'የሰንበት ት/ቤት ክፍል';

  @override
  String get servantDashboardSundaySchoolClassTime => '9:00 ጠዋት - 10:30 ጠዋት';

  @override
  String get servantDashboardBibleStudyReviewTitle => 'የመጽሐፍ ቅዱስ ጥናት ግምገማ';

  @override
  String get servantDashboardBibleStudyReviewTime => '10:30 ጠዋት - 11:00 ጠዋት';

  @override
  String servantDashboardPendingMessage(num cCount, num qCount) {
    String _temp0 = intl.Intl.pluralLogic(
      qCount,
      locale: localeName,
      other: '$qCount ጥያቄዎች',
      one: '1 ጥያቄ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cCount,
      locale: localeName,
      other: '$cCount ቅሬታዎች',
      one: '1 ቅሬታ',
    );
    return '$_temp0 እና $_temp1 በመጠባበቅ ላይ አሉ።';
  }

  @override
  String get servantDashboardViewButton => 'ይመልከቱ';

  @override
  String get servantAnalyticsTitle => 'የክፍል ትንተና';

  @override
  String get servantAnalyticsLoadFailed => 'ትንተናውን መጫን አልተሳካም።';

  @override
  String get servantAnalyticsSubtitle => 'የአፈጻጸም ግንዛቤ እና አዝማሚያዎች';

  @override
  String get servantAnalyticsMetricClassAverage => 'የክፍል አማካኝ';

  @override
  String servantAnalyticsStudentsWithGradesLabel(Object graded, Object total) {
    return '$graded/$total ተማሪዎች';
  }

  @override
  String get servantAnalyticsMetricAtRisk => 'በአደጋ ላይ';

  @override
  String servantAnalyticsAtRiskPercentOfClass(Object percent) {
    return 'ከክፍሉ $percent%';
  }

  @override
  String get servantAnalyticsMetricTopPerformers => 'ከፍተኛ አፈጻጸም';

  @override
  String get servantAnalyticsTopPerformersThreshold => '≥ 90% ያላቸው ተማሪዎች';

  @override
  String get servantAnalyticsMetricMissingWork => 'የጎደለ ስራ';

  @override
  String get servantAnalyticsMissingWorkSubtitle => 'ያልተሟሉ ተማሪዎች';

  @override
  String get servantAnalyticsGradeDistributionTitle => 'የውጤት ስርጭት';

  @override
  String get servantAnalyticsSubjectPerformanceTitle => 'የትምህርት አፈጻጸም';

  @override
  String get servantAnalyticsPerformanceByAssessmentTypeTitle =>
      'በምዘና አይነት የተለያየ አፈጻጸም';

  @override
  String get servantAnalyticsKeyInsightsTitle => 'ዋና ግንዛቤዎች';

  @override
  String get servantAnalyticsNoInsightsYet => 'እስካሁን ግንዛቤ የለም።';

  @override
  String get servantAnalyticsInsightClassPerformingWell =>
      'ክፍሉ በ80%+ አማካኝ ጥሩ እየሰራ ነው';

  @override
  String servantAnalyticsInsightAtRiskStudents(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ተማሪዎች ተጨማሪ ድጋፍ ያስፈልጋቸዋል (ከ70% በታች)',
      one: '1 ተማሪ ተጨማሪ ድጋፍ ያስፈልገዋል (ከ70% በታች)',
    );
    return '$_temp0';
  }

  @override
  String servantAnalyticsInsightIncompleteAssessments(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ተማሪዎች ያልተሟሉ ምዘናዎች አሏቸው',
      one: '1 ተማሪ ያልተሟሉ ምዘናዎች አሉት',
    );
    return '$_temp0';
  }

  @override
  String servantAnalyticsInsightTopPerformers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ተማሪዎች እጅግ ጥሩ እየሰሩ ናቸው (ከፍተኛ $count)',
      one: '1 ተማሪ እጅግ ጥሩ እየሰራ ነው (ከፍተኛ 1)',
    );
    return '$_temp0';
  }

  @override
  String get servantAnalyticsSelectSubjectTitle => 'ትምህርት ይምረጡ';

  @override
  String get servantAnalyticsHighestLabel => 'ከፍተኛ';

  @override
  String get servantAnalyticsLowestLabel => 'ዝቅተኛ';

  @override
  String get servantAnalyticsIncompleteLabel => 'ያልተሟላ';

  @override
  String get servantAnalyticsBackToSubjects => 'ወደ ትምህርቶች ተመለስ';

  @override
  String get servantAnalyticsAssessmentBreakdownTitle => 'የምዘና ዝርዝር';

  @override
  String servantAnalyticsCompletedOutOf(Object completed, Object total) {
    return '$completed/$total ተጠናቋል';
  }

  @override
  String get servantAnalyticsTopPerformersSubtitle => 'ከፍተኛ አማካኝ ያላቸው ተማሪዎች';

  @override
  String get servantAnalyticsStudentsNeedingSupportTitle =>
      'ድጋፍ የሚያስፈልጋቸው ተማሪዎች';

  @override
  String get servantAnalyticsStudentsNeedingSupportSubtitle =>
      'ከ70% በታች አማካኝ - ትኩረት ይፈልጋል';

  @override
  String get servantAnalyticsNeedsHelp => 'እርዳታ ያስፈልጋል';

  @override
  String get servantAnalyticsIncompleteAssessmentsTitle => 'ያልተሟሉ ምዘናዎች';

  @override
  String get servantAnalyticsIncompleteAssessmentsSubtitle =>
      'የጎደለ ስራ ያላቸው ተማሪዎች';

  @override
  String servantAnalyticsSubjectsLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ትምህርቶች',
      one: 'ትምህርት',
    );
    return '$_temp0';
  }

  @override
  String servantAnalyticsAndMore(Object count) {
    return 'እና ሌሎች $count...';
  }

  @override
  String get servantAnalyticsNoStudentsToDisplay => 'ለማሳየት ተማሪ የለም።';

  @override
  String get studentFinalResultsTitle => 'የመጨረሻ ውጤቶች';

  @override
  String studentGradesAcademicYearLabel(Object yearName) {
    return 'የትምህርት ዘመን $yearName';
  }

  @override
  String get studentFinalResultsFinalGradeLabel => 'የመጨረሻ ውጤት';

  @override
  String get studentFinalResultsPromotionStatusLabel => 'የማዕረግ ሁኔታ';

  @override
  String get studentFinalResultsPromotionPromotedTitle => 'ተሻሽሏል';

  @override
  String get studentFinalResultsPromotionPromotedMessage =>
      'እንኳን ደስ አለዎት! ወደ ቀጣዩ ክፍል ተሻሽለዋል።';

  @override
  String get studentFinalResultsPromotionAtRiskTitle => 'በአደጋ ላይ';

  @override
  String get studentFinalResultsPromotionAtRiskMessage =>
      'ወደ ቀጣይ ክፍል ላይ ላትሻሽሉ ይችላሉ። እባክዎ ከመምህርዎ ጋር ያማክሩ።';

  @override
  String get studentFinalResultsPromotionNotPromotedTitle => 'አልተሻሽለም';

  @override
  String get studentFinalResultsPromotionNotPromotedMessage =>
      'የማሻሻያ መስፈርቶችን አላሟሉም። እባክዎ ከመምህርዎ ጋር ያማክሩ።';

  @override
  String get studentFinalResultsFinalSubjectGradesTitle => 'የትምህርት መጨረሻ ውጤቶች';

  @override
  String get studentFinalResultsFinalSummaryTitle => 'የመጨረሻ ማጠቃለያ';

  @override
  String get studentGradesHighestGradeLabel => 'ከፍተኛ ውጤት';

  @override
  String get studentGradesLowestGradeLabel => 'ዝቅተኛ ውጤት';

  @override
  String get studentGradesOverallAverageLabel => 'አጠቃላይ አማካኝ';

  @override
  String studentFinalResultsAcademicYearEndedMessage(Object yearName) {
    return 'የትምህርት ዘመኑ ተጠናቋል። እነዚህ ለ$yearName የመጨረሻ ውጤቶችዎ ናቸው። እረፍትዎን ይደሰቱ እና በቀጣዩ የትምህርት ዘመን እንገናኛለን!';
  }

  @override
  String get studentGradesKeepUpExcellentWork => 'ጥሩ ስራዎን ቀጥሉ!';

  @override
  String studentGradesAssessmentsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ምዘናዎች',
      one: '1 ምዘና',
    );
    return '$_temp0';
  }

  @override
  String get studentGradesAssessmentBreakdownTitle => 'የምዘና ዝርዝር';

  @override
  String studentGradesMissingAssessmentsWarning(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '⚠️ በዚህ ትምህርት $count ምዘናዎች ያልተሞሉ አሉ። ውጤትዎ በተጠናቀቁ ምዘናዎች ላይ ብቻ ይተመናል።',
      one: '⚠️ በዚህ ትምህርት 1 ምዘና ያልተሞላ አለ። ውጤትዎ በተጠናቀቁ ምዘናዎች ላይ ብቻ ይተመናል።',
    );
    return '$_temp0';
  }

  @override
  String studentGradesPointsLabel(Object maxScore, Object score) {
    return '$score/$maxScore ነጥብ';
  }

  @override
  String get studentGradesPerformanceSummaryTitle => 'የአፈጻጸም ማጠቃለያ';

  @override
  String get studentGradesTotalSubjectsLabel => 'ጠቅላላ ትምህርቶች';

  @override
  String get servantGradesLoadSubjectsFailed => 'ትምህርቶችን መጫን አልተሳካም።';

  @override
  String get servantGradesLoadStudentsFailed => 'ተማሪዎችን መጫን አልተሳካም።';

  @override
  String get servantGradesLoadGradeEntriesFailed => 'የውጤት ምዝገባዎችን መጫን አልተሳካም።';

  @override
  String get servantGradesLockedByAdminSettings =>
      'የውጤት አስተዳደር በአስተዳዳሪ ቅንብሮች ታግዷል።';

  @override
  String get servantGradesThisAcademicYear => 'ይህ የትምህርት ዓመት';

  @override
  String servantGradesAcademicYearEndedLocked(Object yearName) {
    return 'የትምህርት ዓመት $yearName ተጠናቋል። የውጤት አስተዳደር ታግዷል።';
  }

  @override
  String get servantGradesLocked => 'የውጤት አስተዳደር ታግዷል።';

  @override
  String get servantGradesDefaultAssessmentType => 'ምዘና';

  @override
  String servantGradesMissingAssessmentsTitle(Object subjectName) {
    return 'ያልተሟሉ ምዘናዎች - $subjectName';
  }

  @override
  String servantGradesStudentsWithIncompleteAssessments(Object count) {
    return 'ያልተሟሉ ምዘናዎች ያላቸው ተማሪዎች: $count';
  }

  @override
  String get servantGradesNoMissingAssessmentsFound => 'ያልተሟሉ ምዘናዎች አልተገኙም።';

  @override
  String get servantAnnouncementsEnterTitleAndMessageError =>
      'እባክዎ ርዕስ እና መልዕክት ያስገቡ።';

  @override
  String get servantAnnouncementsSavedLocallySyncFailed =>
      'በአካባቢ ተቀምጧል፤ ማመሳሰል አልተሳካም።';

  @override
  String get servantAnnouncementsCreateTitle => 'ማስታወቂያ ፍጠር';

  @override
  String get servantAnnouncementsCategoryLabel => 'ምድብ';

  @override
  String get servantAnnouncementsSelectCategoryHint => 'ምድብ ይምረጡ';

  @override
  String get servantAnnouncementsTitleHint => 'ርዕስ';

  @override
  String get servantAnnouncementsMessageLabel => 'መልዕክት';

  @override
  String get servantAnnouncementsMessageHint => 'ማስታወቂያዎን ይጻፉ...';

  @override
  String get servantAnnouncementsPostButton => 'አሳትም';

  @override
  String get servantAnnouncementsEmptyTitle => 'እስካሁን ማስታወቂያ የለም';

  @override
  String get servantAnnouncementsEmptySubtitle =>
      'ለተማሪዎች ዝማኔዎችን ለማጋራት ማስታወቂያ ይፍጠሩ።';

  @override
  String servantAnnouncementsReadCount(Object read, Object total) {
    return '$read / $total ተነብቧል';
  }

  @override
  String servantAnnouncementsTarget(Object audience) {
    return 'ዒላማ: $audience';
  }

  @override
  String servantAnnouncementsStudentsReadCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ተማሪዎች አንብበዋል',
      one: '1 ተማሪ አንብቧል',
    );
    return '$_temp0';
  }

  @override
  String get servantAnnouncementsDeleteTitle => 'ማስታወቂያ ይሰረዝ?';

  @override
  String get servantAnnouncementsDeleteBody => 'ማስታወቂያው ለሁሉም ይሰረዛል።';

  @override
  String get servantAnnouncementsDeleteFailed => 'ማስታወቂያውን መሰረዝ አልተሳካም።';

  @override
  String get profileErrorNotSignedIn => 'ገብተው አይገኙም።';

  @override
  String get profileErrorNotFound => 'መገለጫ አልተገኘም።';

  @override
  String get servantFeedbackSelectTypeTitle => 'አይነት ይምረጡ';

  @override
  String get servantFeedbackTypeTeacherEvaluation => 'የአስተማሪ ግምገማ';

  @override
  String get servantFeedbackTypeCourseEvaluation => 'የትምህርት ግምገማ';

  @override
  String get servantFeedbackTypeSemesterEvaluation => 'የሴሚስተር ግምገማ';

  @override
  String get servantFeedbackTypeGeneral => 'አጠቃላይ';

  @override
  String get servantFeedbackCreateFormButton => 'የግብረመልስ ቅጽ ፍጠር';

  @override
  String get servantFeedbackEmptyTitle => 'እስካሁን የግብረመልስ ቅጾች የሉም';

  @override
  String get servantFeedbackEmptySubtitle => 'የተማሪ ግብረመልስ ለመሰብሰብ ቅጽ ይፍጠሩ';

  @override
  String get servantFeedbackActiveFormsLabel => 'ንቁ ቅጾች';

  @override
  String get servantFeedbackStatusActive => 'ንቁ';

  @override
  String get servantFeedbackStatusExpired => 'ጊዜው አልፎታል';

  @override
  String servantFeedbackQuestionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ጥያቄዎች',
      one: '1 ጥያቄ',
    );
    return '$_temp0';
  }

  @override
  String get servantFeedbackDeleteFormTitle => 'የግብረመልስ ቅጽ ይሰረዝ?';

  @override
  String servantFeedbackDeleteFormBody(Object responseCount) {
    return 'ቅጹን እና የተማሪዎች $responseCount ምላሾችን በቋሚነት ይሰርዛል። ይህ እርምጃ መመለስ አይቻልም።';
  }

  @override
  String servantFeedbackDueLabel(Object date) {
    return 'የመጨረሻ ቀን: $date';
  }

  @override
  String servantFeedbackResponsesCount(Object submitted, Object total) {
    return '$submitted/$total ምላሾች';
  }

  @override
  String get servantFeedbackViewAnalyticsButton => 'ትንተና ይመልከቱ';

  @override
  String get servantFeedbackCreateFormTitle => 'የግብረመልስ ቅጽ ፍጠር';

  @override
  String get servantFeedbackCreateFormSubmitButton => 'ቅጽ ፍጠር';

  @override
  String get servantFeedbackTitleLabel => 'ርዕስ';

  @override
  String get servantFeedbackTitleHint => 'ለምሳሌ፦ የአጋማሽ ሴሚስተር የአስተማሪ ግምገማ';

  @override
  String get servantFeedbackDescriptionLabel => 'መግለጫ';

  @override
  String get servantFeedbackDescriptionHint => 'የግብረመልስ ቅጹን አጭር መግለጫ';

  @override
  String get servantFeedbackTypeLabel => 'አይነት';

  @override
  String get servantFeedbackStartDateLabel => 'መጀመሪያ:';

  @override
  String get servantFeedbackEndDateLabel => 'መጨረሻ:';

  @override
  String get servantFeedbackQuestionsSectionTitle => 'ጥያቄዎች';

  @override
  String servantFeedbackTextResponsesReceived(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count የጽሑፍ መልሶች ተቀብለናል',
      one: '1 የጽሑፍ መልስ ተቀብለናል',
      zero: '0 የጽሑፍ መልስ ተቀብለናል',
    );
    return '$_temp0';
  }

  @override
  String servantFeedbackQuestionsAddedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ጥያቄዎች ተጨምረዋል',
      one: '1 ጥያቄ ተጨምሯል',
      zero: 'ምንም ጥያቄ አልተጨመረም',
    );
    return '$_temp0';
  }

  @override
  String get servantFeedbackAddQuestionButton => 'ጥያቄ ጨምር';

  @override
  String get servantFeedbackRequiredLabel => 'አስፈላጊ';

  @override
  String get servantFeedbackNewQuestionTitle => 'አዲስ ጥያቄ';

  @override
  String get servantFeedbackQuestionTextLabel => 'የጥያቄ ጽሁፍ';

  @override
  String get servantFeedbackQuestionTextHint => 'ጥያቄዎን ያስገቡ...';

  @override
  String get servantFeedbackQuestionTypeLabel => 'የጥያቄ አይነት';

  @override
  String get servantFeedbackQuestionTypeRating => 'ደረጃ (1-5)';

  @override
  String get servantFeedbackQuestionTypeText => 'ጽሁፍ';

  @override
  String get servantFeedbackQuestionTypeMultipleChoice => 'ብዙ ምርጫ';

  @override
  String get servantFeedbackRequiredQuestionLabel => 'አስፈላጊ?';

  @override
  String get servantFeedbackYes => 'አዎ';

  @override
  String get servantFeedbackNo => 'አይ';

  @override
  String get servantFeedbackOptionsLabel => 'ምርጫዎች';

  @override
  String servantFeedbackOptionHint(Object number) {
    return 'ምርጫ $number';
  }

  @override
  String get servantFeedbackAddOptionButton => 'ምርጫ ጨምር';

  @override
  String get servantFeedbackMultipleChoiceNeedsTwoOptions =>
      'የብዙ ምርጫ ጥያቄዎች ቢያንስ 2 ምርጫዎች ያስፈልጋቸዋል።';

  @override
  String get servantFeedbackFormNotFoundTitle => 'ቅጹ አልተገኘም';

  @override
  String get servantFeedbackFormNotFoundSubtitle =>
      'እባክዎ ወደ ኋላ ተመልሰው እንደገና ይሞክሩ።';

  @override
  String get servantFeedbackAnalyticsTitle => 'የግብረመልስ ትንተና';

  @override
  String servantFeedbackQuestionsAndDueLine(num count, Object date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ጥያቄዎች',
      one: '1 ጥያቄ',
    );
    return '$_temp0 • የመጨረሻ ቀን: $date';
  }

  @override
  String get servantFeedbackSubmissionStatisticsTitle => 'የማስገባት ስታቲስቲክስ';

  @override
  String get servantFeedbackSubmittedLabel => 'የተላኩ';

  @override
  String get servantFeedbackPendingLabel => 'ቀርቷል';

  @override
  String get servantFeedbackRateLabel => 'መጠን';

  @override
  String get servantFeedbackNoResponsesTitle => 'እስካሁን ምላሾች የሉም';

  @override
  String get servantFeedbackNoResponsesSubtitle =>
      'ተማሪዎች ግብረመልስ ሲያስገቡ ትንተናው እዚህ ይታያል';

  @override
  String get servantFeedbackAverageRatingLabel => 'አማካኝ ደረጃ';

  @override
  String get servantFeedbackDistributionLabel => 'ስርጭት:';

  @override
  String servantFeedbackResponsesCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ምላሾች',
      one: '1 ምላሽ',
    );
    return '$_temp0';
  }

  @override
  String get servantFeedbackEnterTitleError => 'እባክዎ ርዕስ ያስገቡ።';

  @override
  String get servantFeedbackEnterDescriptionError => 'እባክዎ መግለጫ ያስገቡ።';

  @override
  String get servantFeedbackAddAtLeastOneQuestionError =>
      'እባክዎ በግብረመልስ ቅጹ ውስጥ ቢያንስ አንድ ጥያቄ ያክሉ።';

  @override
  String get servantFeedbackValidDatesError =>
      'እባክዎ ትክክለኛ የመጀመሪያ እና የመጨረሻ ቀናት (YYYY-MM-DD) ያስገቡ።';

  @override
  String get servantFeedbackEndAfterStartError =>
      'የመጨረሻ ቀን ከመጀመሪያ ቀን በኋላ መሆን አለበት።';

  @override
  String get servantFeedbackSelectTypeError => 'እባክዎ አይነት ይምረጡ።';
}
