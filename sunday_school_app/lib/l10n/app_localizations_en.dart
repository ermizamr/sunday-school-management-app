// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ተከታታይ ትምህርት\nዘእግዚአብሔር ምስሌነ';

  @override
  String get roleSelectionTitle => 'Sunday School';

  @override
  String get roleSelectionSubtitle => 'Digital Management System';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleStudentSubtitle => 'View grades, attendance & communication';

  @override
  String get roleServant => 'Servant';

  @override
  String get roleServantSubtitle => 'Manage class, grades & attendance';

  @override
  String get roleSelectPrompt => 'Select your role to continue';

  @override
  String get navHome => 'Home';

  @override
  String get navAttendance => 'Attendance';

  @override
  String get navGrades => 'Grades';

  @override
  String get navCommunication => 'Communication';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonBackToHome => 'Back to home';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSend => 'Send';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonHigh => 'High';

  @override
  String get commonMedium => 'Medium';

  @override
  String get commonLow => 'Low';

  @override
  String get commonAll => 'All';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonUpdate => 'Update';

  @override
  String get commonTryChangingFilters => 'Try changing the filters.';

  @override
  String get commonBack => 'Back';

  @override
  String get commonPrev => 'Prev';

  @override
  String get commonNext => 'Next';

  @override
  String get commonPending => 'Pending';

  @override
  String commonQuestionShort(Object number) {
    return 'Q$number';
  }

  @override
  String get commonDate => 'Date';

  @override
  String get commonYou => 'You';

  @override
  String get commonAddDate => 'Add date';

  @override
  String get commonNa => 'N/A';

  @override
  String get commonNoSubjectsForGrade => 'No subjects found for your grade.';

  @override
  String commonWarningMessage(Object message) {
    return '⚠️ $message';
  }

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get errorSomethingWentWrong =>
      'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'Network error. Check your internet connection and try again.';

  @override
  String get errorAuthRequired => 'Please sign in to continue.';

  @override
  String get errorMissingActiveAcademicYear =>
      'No active academic year is set. Please contact your administrator.';

  @override
  String get errorMissingGradeAssignment =>
      'You are not assigned to a grade yet. Please contact your administrator.';

  @override
  String get profileAccountDetailsSubtitle => 'Account details';

  @override
  String get profileLoadFailedTitle => 'Could not load profile';

  @override
  String get profileNotAssigned => 'Not assigned';

  @override
  String get profileAcademicIdLabel => 'Academic ID';

  @override
  String get profileGradeLabel => 'Grade';

  @override
  String get profileAccountStatusLabel => 'Account status';

  @override
  String get profileRoleLabel => 'Role';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get profileChangePasswordSubtitle =>
      'Set a new password for your account';

  @override
  String get accountStatusActive => 'Active';

  @override
  String get accountStatusInactive => 'Inactive';

  @override
  String get accountStatusSuspended => 'Suspended';

  @override
  String get accountStatusDisabled => 'Disabled';

  @override
  String get servantGradesDeleteAssessmentTitle => 'Delete assessment?';

  @override
  String servantGradesDeleteAssessmentBody(Object name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get servantGradesDeleteAssessmentFailed =>
      'Failed to delete assessment.';

  @override
  String get servantGradesFillRequiredFieldsError =>
      'Please fill all required fields.';

  @override
  String get servantGradesWeightRangeError =>
      'Weight must be between 0 and 100.';

  @override
  String servantGradesInvalidScore(Object maxScore, Object student) {
    return 'Invalid score for $student. Must be 0-$maxScore.';
  }

  @override
  String get servantGradesAssessmentUpdated => 'Assessment updated.';

  @override
  String get servantGradesAssessmentAdded => 'Assessment added.';

  @override
  String get servantGradesSaveAssessmentFailed => 'Failed to save assessment.';

  @override
  String get servantGradesSubjectNameRequired => 'Subject name is required.';

  @override
  String get servantGradesSubjectAdded => 'Subject added.';

  @override
  String get servantGradesSubjectAddFailed => 'Failed to add subject.';

  @override
  String get servantGradesAddNewAssessment => 'Add New Assessment';

  @override
  String get servantGradesHideGrades => 'Hide Grades';

  @override
  String get servantGradesAllGrades => 'All Grades';

  @override
  String get servantGradesMissing => 'Missing';

  @override
  String get servantGradesTotalWeightLabel => 'Total Weight:';

  @override
  String get servantGradesTotalWeightExceeds => 'Total weight exceeds 100%';

  @override
  String servantGradesRemainingToReach100(Object remaining) {
    return '$remaining% remaining to reach 100%';
  }

  @override
  String get servantGradesAddAssessmentTitle => 'Add Assessment';

  @override
  String get servantGradesEditAssessmentTitle => 'Edit Assessment';

  @override
  String servantGradesClassAvgLabel(Object percent) {
    return 'Class Avg: $percent%';
  }

  @override
  String get servantGradesStudentScoresOptional => 'Student Scores (Optional)';

  @override
  String get servantGradesSearchStudentsHint => 'Search students...';

  @override
  String servantGradesPageLabel(Object current, Object total) {
    return 'Page $current / $total';
  }

  @override
  String get servantGradesScoreHint => 'Score';

  @override
  String get servantGradesAddSubjectTitle => 'Add Subject';

  @override
  String get servantGradesSubjectNameHint => 'Subject name (e.g., Theology)';

  @override
  String get servantGradesManageTitle => 'Manage Grades';

  @override
  String get servantGradesNewSubjectChip => 'New Subject';

  @override
  String servantGradesWeightedTitle(Object subjectName) {
    return 'Student Weighted Grades - $subjectName';
  }

  @override
  String servantGradesWeightedBasedOn(num count, Object totalWeight) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count assessments with $totalWeight% total weight',
      one: 'Based on 1 assessment with $totalWeight% total weight',
    );
    return '$_temp0';
  }

  @override
  String get servantGradesWeightedSearchByStudentNameHint =>
      'Search by student name...';

  @override
  String get servantGradesWeightedStudentNameHeader => 'Student Name';

  @override
  String get servantGradesWeightedScoreHeader => 'Weighted Score';

  @override
  String get servantGradesWeightedGradeHeader => 'Grade';

  @override
  String get servantGradesWeightedClassAverageLabel => 'Class Average';

  @override
  String get servantGradesWeightedHighestLabel => 'Highest';

  @override
  String get servantGradesWeightedLowestLabel => 'Lowest';

  @override
  String get servantGradesMissingLabel => 'Missing:';

  @override
  String get servantGradesIncomplete => 'Incomplete';

  @override
  String servantGradesMissingCount(Object count) {
    return '$count missing';
  }

  @override
  String servantGradesMaxPoints(Object maxScore) {
    return 'Max: $maxScore points';
  }

  @override
  String get servantGradesEditGradesTooltip => 'Edit grades';

  @override
  String get servantGradesDeleteAssessmentTooltip => 'Delete assessment';

  @override
  String get servantGradesClassAverageLabel => 'Class average';

  @override
  String get servantGradesHideStudentScores => 'Hide Student Scores';

  @override
  String get servantGradesViewStudentScores => 'View Student Scores';

  @override
  String get servantGradesNoAssessmentsYetTitle => 'No assessments yet';

  @override
  String get servantGradesNoAssessmentsYetBody =>
      'Add an assessment to start tracking student scores for this subject.';

  @override
  String get servantGradesAssessmentNameHint =>
      'Assessment name (e.g., Quiz 1)';

  @override
  String get servantGradesMaxScoreHint => 'Max score';

  @override
  String get servantGradesWeightPercentOptionalHint => 'Weight % (optional)';

  @override
  String get authStudentLoginTitle => 'Student Login';

  @override
  String get authServantLoginTitle => 'Servant Login';

  @override
  String get authLoginSubtitle => 'Enter your credentials to continue';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authNewPasswordHint => 'Enter a new password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authConfirmPasswordHint => 'Re-enter your new password';

  @override
  String get authEmailRequiredError => 'Please enter your email';

  @override
  String get authPasswordRequiredError => 'Please enter your password';

  @override
  String get authConfirmPasswordRequiredError => 'Please confirm your password';

  @override
  String get authPasswordMismatchError => 'Passwords do not match';

  @override
  String authPasswordMinLengthError(Object min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get authLoginButton => 'Login';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authForgotPasswordDialogTitle => 'Change password';

  @override
  String get authForgotPasswordDialogBody =>
      'To change your password, please contact your class admin.';

  @override
  String get authDemoMode =>
      'Demo mode: use any valid email & password\nwhile backend is being wired fully.';

  @override
  String get authInvalidCredentialsError => 'Incorrect email or password.';

  @override
  String get authLoginFailedGeneric => 'Login failed. Please try again.';

  @override
  String get authRoleMismatchStudent =>
      'This account is not a student account. Please select Servant role to continue.';

  @override
  String get authRoleMismatchServant =>
      'This account is not a servant account. Please select Student role to continue.';

  @override
  String get authRoleVerificationFailed =>
      'Could not verify your account role. Please try again.';

  @override
  String get authPasswordUpdateSuccess => 'Password updated.';

  @override
  String get authPasswordUpdateFailedGeneric =>
      'Could not update password. Please try again.';

  @override
  String get dashboardWelcome => 'Welcome!';

  @override
  String get dashboardAttendanceStat => 'Attendance';

  @override
  String get dashboardAverageScoreStat => 'Average score';

  @override
  String get dashboardCommunicationTitle => 'Communication';

  @override
  String dashboardPendingCount(Object count) {
    return '$count pending';
  }

  @override
  String get dashboardPendingQuestions => 'Pending Questions';

  @override
  String get dashboardOpenComplaints => 'Open Complaints';

  @override
  String get dashboardGoToCommunication => 'Go to Communication';

  @override
  String get dashboardQuickActions => 'Quick Actions';

  @override
  String get dashboardViewGrades => 'View Grades';

  @override
  String get studentDashboardLoadFailed =>
      'Could not load dashboard data. Please try again.';

  @override
  String get attendanceTrackSubtitle => 'Track your class participation';

  @override
  String get attendanceOverallTitle => 'Overall Attendance';

  @override
  String get attendanceAcrossAllSubjects => 'across all subjects';

  @override
  String get attendanceLoadFailed =>
      'Failed to load attendance. Please try again.';

  @override
  String attendancePercentLabel(Object percent) {
    return '$percent% attendance';
  }

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendancePermission => 'Permission';

  @override
  String get attendancePerformanceExcellent => 'Excellent attendance!';

  @override
  String get attendancePerformanceGreat => 'Great attendance!';

  @override
  String get attendancePerformanceGood => 'Good attendance';

  @override
  String get attendancePerformanceNeedsImprovement =>
      'Attendance needs improvement';

  @override
  String get attendanceHistoryTitle => 'Attendance History';

  @override
  String attendanceSessionsRecorded(Object count) {
    return '$count sessions recorded';
  }

  @override
  String get attendanceNoRecordsYet => 'No attendance records yet';

  @override
  String get attendanceImproveTitle => 'Improve Your Attendance';

  @override
  String get attendanceImproveBody =>
      'Regular attendance is important for your learning and promotion. Try to attend all classes and arrive on time.';

  @override
  String get servantAttendanceChooseSubjectAndDate =>
      'Choose a subject and a date';

  @override
  String get servantAttendanceMinimumDaysAbsent => 'Minimum days absent';

  @override
  String get servantAttendanceMinAbsentHint => 'Enter minimum absent days';

  @override
  String servantAttendanceStudentsAbsentAtLeast(Object days) {
    return 'Students absent for at least $days day(s):';
  }

  @override
  String get servantAttendanceNoStudentsMatch => 'No students match.';

  @override
  String servantAttendanceAbsentDays(Object days) {
    return '$days absent';
  }

  @override
  String get servantAttendancePreviousDates => 'Previous dates';

  @override
  String get servantAttendanceNoDatesYet => 'No attendance dates yet.';

  @override
  String get servantAttendanceSearchStudentsHint => 'Search students';

  @override
  String get servantAttendanceLoadFailed =>
      'Failed to load attendance data. Please try again.';

  @override
  String get servantAttendanceSaved => 'Attendance saved';

  @override
  String get servantAttendanceSaveFailed => 'Failed to save attendance';

  @override
  String get commAnnouncements => 'Announcements';

  @override
  String get commQuestions => 'Questions';

  @override
  String get commComplaints => 'Complaints';

  @override
  String get commFeedback => 'Feedback';

  @override
  String get servantCommSubtitle =>
      'Announcements, questions, complaints, and feedback.';

  @override
  String get pushChannelCommunicationsName => 'Communications';

  @override
  String get pushChannelCommunicationsDescription =>
      'Announcements and communication updates';

  @override
  String get pushNotificationNewUpdateTitle => 'New update';

  @override
  String get pushNotificationQuestionAnsweredTitle => 'Answer to your question';

  @override
  String get pushNotificationComplaintRespondedTitle =>
      'Response to your complaint';

  @override
  String get commNoAnnouncements => 'No announcements';

  @override
  String get commAnnouncementsEmptySubtitle => 'Check back later for updates';

  @override
  String get commAnnouncementsLoadFailed => 'Failed to load announcements.';

  @override
  String get commLoadQuestionsFailed => 'Failed to load questions.';

  @override
  String get commLoadComplaintsFailed => 'Failed to load complaints.';

  @override
  String get commLoadFeedbackFormsFailed => 'Failed to load feedback forms.';

  @override
  String get commLoadContextFailed =>
      'Failed to load required information. Please try again.';

  @override
  String get commSubmitQuestionFailed =>
      'Failed to submit question. Please try again.';

  @override
  String get commSubmitComplaintFailed =>
      'Failed to submit complaint. Please try again.';

  @override
  String get commSubmitFeedbackFailed =>
      'Failed to submit feedback. Please try again.';

  @override
  String get servantCommLoadQuestionsFailed => 'Failed to load questions.';

  @override
  String get servantCommLoadComplaintsFailed => 'Failed to load complaints.';

  @override
  String get servantCommSendResponseFailed =>
      'Failed to send response. Please try again.';

  @override
  String get servantCommUpdateComplaintFailed =>
      'Failed to update complaint. Please try again.';

  @override
  String get commAnnouncementCategoryUrgent => 'Urgent';

  @override
  String get commAnnouncementCategoryGrades => 'Grades';

  @override
  String get commAnnouncementCategorySchedule => 'Schedule';

  @override
  String get commAnnouncementCategoryEvent => 'Event';

  @override
  String get commAnnouncementCategoryGeneral => 'General';

  @override
  String commPostedBy(Object name) {
    return 'Posted by $name';
  }

  @override
  String get commAskQuestion => 'Ask a Question';

  @override
  String get commPending => 'Pending';

  @override
  String get commAnswered => 'Answered';

  @override
  String get commInReview => 'In review';

  @override
  String get commResolved => 'Resolved';

  @override
  String get commNoQuestionsYet => 'No questions yet';

  @override
  String get commResponseLabel => 'Response:';

  @override
  String get servantCommNoComplaints => 'No complaints';

  @override
  String get servantCommRespond => 'Respond';

  @override
  String get servantCommTypeResponseHint => 'Type your response...';

  @override
  String get servantCommEnterResponseError => 'Please enter a response.';

  @override
  String get servantCommSavedLocallySyncFailed => 'Saved locally; sync failed.';

  @override
  String get servantCommSendResponse => 'Send response';

  @override
  String get servantCommDeleteQuestionTitle => 'Delete question?';

  @override
  String get servantCommDeleteQuestionBody =>
      'This will permanently remove this question.';

  @override
  String get servantCommDeleteQuestionPermissionDenied =>
      'You may not have permission to delete questions.';

  @override
  String get servantCommDeleteComplaintTitle => 'Delete complaint?';

  @override
  String get servantCommDeleteComplaintBody =>
      'This will permanently remove this complaint.';

  @override
  String get servantCommDeleteFromServerFailed =>
      'Could not delete from server.';

  @override
  String get commSubjectBibleStudies => 'Bible Studies';

  @override
  String get commSubjectChristianHistory => 'Christian History';

  @override
  String get commSubjectGeneral => 'General';

  @override
  String get commSubjectLabel => 'Subject';

  @override
  String get commYourQuestionLabel => 'Your Question';

  @override
  String get commQuestionHint => 'Type your question here...';

  @override
  String get commSelectSubjectError => 'Please select a subject';

  @override
  String get commEnterQuestionError => 'Please enter your question';

  @override
  String get commQuestionSubmitted => 'Question submitted!';

  @override
  String get commSubmitComplaint => 'Submit Complaint';

  @override
  String get commNoComplaintsSubmitted => 'No complaints submitted';

  @override
  String get commCategoryLabel => 'Category';

  @override
  String get commCategoryTeacher => 'Teacher';

  @override
  String get commCategoryFacility => 'Facility';

  @override
  String get commCategoryCourse => 'Course';

  @override
  String get commCategoryAdministrative => 'Administrative';

  @override
  String get commCategoryOther => 'Other';

  @override
  String get commSelectCategoryError => 'Please select a category';

  @override
  String get commTitleLabel => 'Title';

  @override
  String get commComplaintTitleHint => 'Brief title for your complaint';

  @override
  String get commEnterTitleError => 'Please enter a title';

  @override
  String get commDescriptionLabel => 'Description';

  @override
  String get commComplaintDescriptionHint =>
      'Describe your complaint in detail...';

  @override
  String get commEnterDescriptionError => 'Please enter a description';

  @override
  String get commSubmitAnonymously => 'Submit anonymously';

  @override
  String get commComplaintSubmitted => 'Complaint submitted!';

  @override
  String get commNoActiveFeedbackForms => 'No active feedback forms';

  @override
  String get commFeedbackEmptySubtitle =>
      'Your servant may share feedback forms in the future. Check back later.';

  @override
  String get bootstrapErrorTitle => 'App startup failed';

  @override
  String get bootstrapErrorFix =>
      'Fix: check your internet connection and try again.';

  @override
  String get bootstrapErrorVerifyPath =>
      'If the problem persists, contact your administrator.';

  @override
  String get servantDashboardTitle => 'Servant Dashboard';

  @override
  String get servantDashboardSubtitle => 'Class Management';

  @override
  String get servantDashboardLoadFailed =>
      'Could not load dashboard data. Please try again.';

  @override
  String get servantTotalStudents => 'Total Students';

  @override
  String get servantDashboardAvgAttendanceLabel => 'Avg Attendance';

  @override
  String get servantDashboardPendingItemsLabel => 'Pending Items';

  @override
  String get servantDashboardQuickActionsTitle => 'Quick Actions';

  @override
  String get servantDashboardMarkAttendanceTitle => 'Mark Attendance';

  @override
  String get servantDashboardMarkAttendanceSubtitle =>
      'Record today\'s attendance';

  @override
  String get servantDashboardAddGradesTitle => 'Add Grades';

  @override
  String get servantDashboardAddGradesSubtitle =>
      'Enter or update student grades';

  @override
  String get servantRegisterStudentQuickActionTitle => 'Register Student';

  @override
  String get servantRegisterStudentQuickActionSubtitle =>
      'Add a new student to a grade';

  @override
  String get servantRegisterStudentTitle => 'Register Student';

  @override
  String get servantRegisterStudentFullNameLabel => 'Student full name';

  @override
  String get servantRegisterStudentFullNameHint => 'e.g., John Doe';

  @override
  String get servantRegisterStudentGradeLabel => 'Registering grade';

  @override
  String get servantRegisterStudentNoGradesMessage =>
      'No grades found. Please contact your class admin.';

  @override
  String get servantRegisterStudentSubmit => 'Register';

  @override
  String get servantRegisterStudentNameRequired =>
      'Please enter the student\'s full name';

  @override
  String get servantRegisterStudentGradeRequired => 'Please select a grade';

  @override
  String get servantRegisterStudentFailedGeneric =>
      'Could not register student. Please try again.';

  @override
  String get servantRegisterStudentSuccessTitle => 'Student registered';

  @override
  String servantRegisterStudentSuccessMessage(Object academicId) {
    return 'Academic ID: $academicId\nInitial password: same as Academic ID';
  }

  @override
  String get servantDashboardGradeAnalyticsSubtitle =>
      'Performance insights & trends';

  @override
  String get servantDashboardTodayScheduleTitle => 'Today\'s Schedule';

  @override
  String get servantDashboardSundaySchoolClassTitle => 'Sunday School Class';

  @override
  String get servantDashboardSundaySchoolClassTime => '9:00 AM - 10:30 AM';

  @override
  String get servantDashboardBibleStudyReviewTitle => 'Bible Study Review';

  @override
  String get servantDashboardBibleStudyReviewTime => '10:30 AM - 11:00 AM';

  @override
  String servantDashboardPendingMessage(num cCount, num qCount) {
    String _temp0 = intl.Intl.pluralLogic(
      qCount,
      locale: localeName,
      other: 'You have $qCount questions',
      one: 'You have 1 question',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cCount,
      locale: localeName,
      other: '$cCount complaints',
      one: '1 complaint',
    );
    return '$_temp0 and $_temp1 pending';
  }

  @override
  String get servantDashboardViewButton => 'View';

  @override
  String get servantAnalyticsTitle => 'Grade Analytics';

  @override
  String get servantAnalyticsLoadFailed => 'Failed to load analytics.';

  @override
  String get servantAnalyticsSubtitle => 'Performance Insights & Trends';

  @override
  String get servantAnalyticsTabOverview => 'Overview';

  @override
  String get servantAnalyticsTabBySubject => 'By Subject';

  @override
  String get servantAnalyticsTabStudents => 'Students';

  @override
  String get servantAnalyticsMetricClassAverage => 'Class Average';

  @override
  String servantAnalyticsStudentsWithGradesLabel(Object graded, Object total) {
    return '$graded/$total students';
  }

  @override
  String get servantAnalyticsMetricAtRisk => 'At-Risk';

  @override
  String servantAnalyticsAtRiskPercentOfClass(Object percent) {
    return '$percent% of class';
  }

  @override
  String get servantAnalyticsMetricTopPerformers => 'Top Performers';

  @override
  String get servantAnalyticsTopPerformersThreshold => 'Students ≥ 90%';

  @override
  String get servantAnalyticsMetricMissingWork => 'Missing Work';

  @override
  String get servantAnalyticsMissingWorkSubtitle => 'Students incomplete';

  @override
  String get servantAnalyticsGradeDistributionTitle => 'Grade Distribution';

  @override
  String get servantAnalyticsSubjectPerformanceTitle => 'Subject Performance';

  @override
  String get servantAnalyticsPerformanceByAssessmentTypeTitle =>
      'Performance by Assessment Type';

  @override
  String get servantAnalyticsKeyInsightsTitle => 'Key Insights';

  @override
  String get servantAnalyticsNoInsightsYet => 'No insights yet.';

  @override
  String get servantAnalyticsInsightClassPerformingWell =>
      'Class is performing well with an average of 80%+';

  @override
  String servantAnalyticsInsightAtRiskStudents(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students need additional support (below 70%)',
      one: '1 student needs additional support (below 70%)',
    );
    return '$_temp0';
  }

  @override
  String servantAnalyticsInsightIncompleteAssessments(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students have incomplete assessments',
      one: '1 student has incomplete assessments',
    );
    return '$_temp0';
  }

  @override
  String servantAnalyticsInsightTopPerformers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students are excelling (top $count)',
      one: '1 student is excelling (top 1)',
    );
    return '$_temp0';
  }

  @override
  String get servantAnalyticsSelectSubjectTitle => 'Select a Subject';

  @override
  String get servantAnalyticsHighestLabel => 'Highest';

  @override
  String get servantAnalyticsLowestLabel => 'Lowest';

  @override
  String get servantAnalyticsIncompleteLabel => 'Incomplete';

  @override
  String get servantAnalyticsBackToSubjects => 'Back to Subjects';

  @override
  String get servantAnalyticsAssessmentBreakdownTitle => 'Assessment Breakdown';

  @override
  String servantAnalyticsCompletedOutOf(Object completed, Object total) {
    return '$completed/$total completed';
  }

  @override
  String get servantAnalyticsTopPerformersSubtitle =>
      'Students with highest averages';

  @override
  String get servantAnalyticsStudentsNeedingSupportTitle =>
      'Students Needing Support';

  @override
  String get servantAnalyticsStudentsNeedingSupportSubtitle =>
      'Below 70% average - requires attention';

  @override
  String get servantAnalyticsNeedsHelp => 'Needs help';

  @override
  String get servantAnalyticsIncompleteAssessmentsTitle =>
      'Incomplete Assessments';

  @override
  String get servantAnalyticsIncompleteAssessmentsSubtitle =>
      'Students with missing work';

  @override
  String servantAnalyticsSubjectsLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'subjects',
      one: 'subject',
    );
    return '$_temp0';
  }

  @override
  String servantAnalyticsAndMore(Object count) {
    return 'And $count more...';
  }

  @override
  String get servantAnalyticsNoStudentsToDisplay => 'No students to display.';

  @override
  String get studentFinalResultsTitle => 'Final Results';

  @override
  String studentGradesAcademicYearLabel(Object yearName) {
    return 'Academic Year $yearName';
  }

  @override
  String get studentGradesSemester1ModeMessage =>
      'Semester 1 is in progress. These grades reflect your Semester 1 assessments so far.';

  @override
  String get studentGradesSemester2ModeMessage =>
      'Semester 2 is in progress. These grades reflect your Semester 2 assessments so far.';

  @override
  String get studentGradesBreakModeMessage =>
      'Break period. Grade updates are currently paused.';

  @override
  String get studentGradesAccountInactiveTitle => 'Access denied';

  @override
  String get studentGradesAccountInactiveMessage =>
      'Your account is inactive. Please contact የተከታታይ ትምህርት ዘእግዚአብሔር ምስሌነ ክፍል ኃላፊ.';

  @override
  String get studentFinalResultsFinalGradeLabel => 'Final Grade';

  @override
  String get studentFinalResultsPromotionStatusLabel => 'Promotion Status';

  @override
  String get studentFinalResultsPromotionPromotedTitle => 'Promoted';

  @override
  String get studentFinalResultsPromotionPromotedMessage =>
      'Congratulations! You have been promoted to the next grade.';

  @override
  String get studentFinalResultsPromotionAtRiskTitle => 'At Risk';

  @override
  String get studentFinalResultsPromotionAtRiskMessage =>
      'You are at risk of not being promoted. Please consult with your teacher.';

  @override
  String get studentFinalResultsPromotionNotPromotedTitle => 'Not Promoted';

  @override
  String get studentFinalResultsPromotionNotPromotedMessage =>
      'You have not met the promotion requirements. Please consult with your teacher.';

  @override
  String get studentFinalResultsFinalSubjectGradesTitle =>
      'Final Subject Grades';

  @override
  String get studentFinalResultsFinalSummaryTitle => 'Final Summary';

  @override
  String get studentGradesHighestGradeLabel => 'Highest Grade';

  @override
  String get studentGradesLowestGradeLabel => 'Lowest Grade';

  @override
  String get studentGradesSemester1AverageLabel => 'Semester 1 Average';

  @override
  String get studentGradesSemester2AverageLabel => 'Semester 2 Average';

  @override
  String get studentGradesOverallAverageLabel => 'Overall Average';

  @override
  String studentFinalResultsAcademicYearEndedMessage(Object yearName) {
    return 'The academic year has ended. These are your final grades for $yearName. Enjoy your break and we look forward to seeing you in the next academic year!';
  }

  @override
  String get studentGradesKeepUpExcellentWork => 'Keep up the excellent work!';

  @override
  String studentGradesAssessmentsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assessments',
      one: '1 assessment',
    );
    return '$_temp0';
  }

  @override
  String get studentGradesAssessmentBreakdownTitle => 'Assessment Breakdown';

  @override
  String studentGradesMissingAssessmentsWarning(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '⚠️ You are missing $count assessments in this subject. Your grade is calculated based only on completed assessments.',
      one:
          '⚠️ You are missing 1 assessment in this subject. Your grade is calculated based only on completed assessments.',
    );
    return '$_temp0';
  }

  @override
  String studentGradesPointsLabel(Object maxScore, Object score) {
    return '$score/$maxScore pts';
  }

  @override
  String get studentGradesPerformanceSummaryTitle => 'Performance Summary';

  @override
  String get studentGradesTotalSubjectsLabel => 'Total Subjects';

  @override
  String get gradesLoadFailed => 'Failed to load grades. Please try again.';

  @override
  String get servantGradesLoadSubjectsFailed => 'Failed to load subjects.';

  @override
  String get servantGradesLoadStudentsFailed => 'Failed to load students.';

  @override
  String get servantGradesLoadGradeEntriesFailed =>
      'Failed to load grade entries.';

  @override
  String get servantGradesLockedByAdminSettings =>
      'Grade management is locked by admin settings.';

  @override
  String get servantGradesThisAcademicYear => 'this academic year';

  @override
  String servantGradesAcademicYearEndedLocked(Object yearName) {
    return 'Academic year $yearName has ended. Grade management is locked.';
  }

  @override
  String get servantGradesLocked => 'Grade management is locked.';

  @override
  String get servantGradesDefaultAssessmentType => 'Assessment';

  @override
  String servantGradesMissingAssessmentsTitle(Object subjectName) {
    return 'Missing Assessments - $subjectName';
  }

  @override
  String servantGradesStudentsWithIncompleteAssessments(Object count) {
    return 'Students with incomplete assessments: $count';
  }

  @override
  String get servantGradesNoMissingAssessmentsFound =>
      'No missing assessments found.';

  @override
  String get servantAnnouncementsEnterTitleAndMessageError =>
      'Please enter a title and message.';

  @override
  String get servantAnnouncementsPostFailed =>
      'Failed to post announcement. Please try again.';

  @override
  String get servantAnnouncementsSavedLocallySyncFailed =>
      'Saved locally; sync failed.';

  @override
  String get servantAnnouncementsCreateTitle => 'Create Announcement';

  @override
  String get servantAnnouncementsCategoryLabel => 'Category';

  @override
  String get servantAnnouncementsSelectCategoryHint => 'Select category';

  @override
  String get servantAnnouncementsTitleHint => 'Title';

  @override
  String get servantAnnouncementsMessageLabel => 'Message';

  @override
  String get servantAnnouncementsMessageHint => 'Write your announcement...';

  @override
  String get servantAnnouncementsPostButton => 'Post';

  @override
  String get servantAnnouncementsEmptyTitle => 'No announcements yet';

  @override
  String get servantAnnouncementsEmptySubtitle =>
      'Create an announcement to share updates with students.';

  @override
  String servantAnnouncementsReadCount(Object read, Object total) {
    return '$read / $total read';
  }

  @override
  String servantAnnouncementsTarget(Object audience) {
    return 'Target: $audience';
  }

  @override
  String servantAnnouncementsStudentsReadCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students read',
      one: '1 student read',
    );
    return '$_temp0';
  }

  @override
  String get servantAnnouncementsDeleteTitle => 'Delete announcement?';

  @override
  String get servantAnnouncementsDeleteBody =>
      'This will delete the announcement for everyone.';

  @override
  String get servantAnnouncementsDeleteFailed =>
      'Failed to delete announcement.';

  @override
  String get profileErrorNotSignedIn => 'You are not signed in.';

  @override
  String get profileErrorNotFound => 'Profile not found.';

  @override
  String get servantFeedbackSelectTypeTitle => 'Select type';

  @override
  String get servantFeedbackTypeTeacherEvaluation => 'Teacher Evaluation';

  @override
  String get servantFeedbackTypeCourseEvaluation => 'Course Evaluation';

  @override
  String get servantFeedbackTypeSemesterEvaluation => 'Semester Evaluation';

  @override
  String get servantFeedbackTypeGeneral => 'General';

  @override
  String get servantFeedbackCreateFormButton => 'Create Feedback Form';

  @override
  String get servantFeedbackCreateFormSuccessToast =>
      'Feedback form created successfully!';

  @override
  String get servantFeedbackLoadFormsFailed => 'Failed to load feedback forms.';

  @override
  String get servantFeedbackEmptyTitle => 'No feedback forms yet';

  @override
  String get servantFeedbackEmptySubtitle =>
      'Create a form to collect student feedback';

  @override
  String get servantFeedbackActiveFormsLabel => 'Active Forms';

  @override
  String get servantFeedbackStatusActive => 'Active';

  @override
  String get servantFeedbackStatusExpired => 'Expired';

  @override
  String servantFeedbackQuestionsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get servantFeedbackDeleteFormTitle => 'Delete Feedback Form?';

  @override
  String get servantFeedbackDeleteFormFailed =>
      'Failed to delete feedback form.';

  @override
  String servantFeedbackDeleteFormBody(Object responseCount) {
    return 'This will permanently delete the form and all $responseCount student responses. This action cannot be undone.';
  }

  @override
  String servantFeedbackDueLabel(Object date) {
    return 'Due: $date';
  }

  @override
  String servantFeedbackResponsesCount(Object submitted, Object total) {
    return '$submitted/$total responses';
  }

  @override
  String get servantFeedbackViewAnalyticsButton => 'View Analytics';

  @override
  String get servantFeedbackCreateFormTitle => 'Create Feedback Form';

  @override
  String get servantFeedbackCreateFormSubmitButton => 'Create Form';

  @override
  String get servantFeedbackTitleLabel => 'Title';

  @override
  String get servantFeedbackTitleHint =>
      'e.g., Mid-Semester Teacher Evaluation';

  @override
  String get servantFeedbackDescriptionLabel => 'Description';

  @override
  String get servantFeedbackDescriptionHint =>
      'Brief description of the feedback form';

  @override
  String get servantFeedbackTypeLabel => 'Type';

  @override
  String get servantFeedbackStartDateLabel => 'Start:';

  @override
  String get servantFeedbackEndDateLabel => 'End:';

  @override
  String get servantFeedbackQuestionsSectionTitle => 'Questions';

  @override
  String servantFeedbackTextResponsesReceived(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count text responses received',
      one: '1 text response received',
      zero: '0 text responses received',
    );
    return '$_temp0';
  }

  @override
  String servantFeedbackQuestionsAddedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions added',
      one: '1 question added',
      zero: '0 questions added',
    );
    return '$_temp0';
  }

  @override
  String get servantFeedbackAddQuestionButton => 'Add Question';

  @override
  String get servantFeedbackRequiredLabel => 'Required';

  @override
  String get servantFeedbackNewQuestionTitle => 'New Question';

  @override
  String get servantFeedbackQuestionTextLabel => 'Question Text';

  @override
  String get servantFeedbackQuestionTextHint => 'Enter your question...';

  @override
  String get servantFeedbackQuestionTypeLabel => 'Question Type';

  @override
  String get servantFeedbackQuestionTypeRating => 'Rating (1-5)';

  @override
  String get servantFeedbackQuestionTypeText => 'Text';

  @override
  String get servantFeedbackQuestionTypeMultipleChoice => 'Multiple choice';

  @override
  String get servantFeedbackRequiredQuestionLabel => 'Required?';

  @override
  String get servantFeedbackYes => 'Yes';

  @override
  String get servantFeedbackNo => 'No';

  @override
  String get servantFeedbackOptionsLabel => 'Options';

  @override
  String servantFeedbackOptionHint(Object number) {
    return 'Option $number';
  }

  @override
  String get servantFeedbackAddOptionButton => 'Add Option';

  @override
  String get servantFeedbackMultipleChoiceNeedsTwoOptions =>
      'Multiple choice questions need at least 2 options.';

  @override
  String get servantFeedbackFormNotFoundTitle => 'Form not found';

  @override
  String get servantFeedbackFormNotFoundSubtitle =>
      'Please go back and try again.';

  @override
  String get servantFeedbackAnalyticsTitle => 'Feedback Analytics';

  @override
  String servantFeedbackQuestionsAndDueLine(num count, Object date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0 • Due: $date';
  }

  @override
  String get servantFeedbackSubmissionStatisticsTitle =>
      'Submission Statistics';

  @override
  String get servantFeedbackSubmittedLabel => 'Submitted';

  @override
  String get servantFeedbackPendingLabel => 'Pending';

  @override
  String get servantFeedbackRateLabel => 'Rate';

  @override
  String get servantFeedbackNoResponsesTitle => 'No responses yet';

  @override
  String get servantFeedbackNoResponsesSubtitle =>
      'Analytics will appear here as students submit feedback';

  @override
  String get servantFeedbackLoadResponsesFailed => 'Failed to load responses.';

  @override
  String get servantFeedbackAverageRatingLabel => 'Average Rating';

  @override
  String get servantFeedbackDistributionLabel => 'Distribution:';

  @override
  String servantFeedbackResponsesCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count responses',
      one: '1 response',
    );
    return '$_temp0';
  }

  @override
  String get servantFeedbackEnterTitleError => 'Please enter a title.';

  @override
  String get servantFeedbackEnterDescriptionError =>
      'Please enter a description.';

  @override
  String get servantFeedbackAddAtLeastOneQuestionError =>
      'Please add at least one question to the feedback form.';

  @override
  String get servantFeedbackValidDatesError =>
      'Please select valid start and end dates.';

  @override
  String get servantFeedbackEndAfterStartError =>
      'End date must be after start date.';

  @override
  String get servantFeedbackSelectTypeError => 'Please select a type.';

  @override
  String get servantFeedbackCreateFormFailed =>
      'Failed to create feedback form. Please try again.';
}
