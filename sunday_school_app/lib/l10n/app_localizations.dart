import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DEAS EMSS'**
  String get appTitle;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunday School'**
  String get roleSelectionTitle;

  /// No description provided for @roleSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Management System'**
  String get roleSelectionSubtitle;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleStudentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View grades, attendance & communication'**
  String get roleStudentSubtitle;

  /// No description provided for @roleServant.
  ///
  /// In en, this message translates to:
  /// **'Servant'**
  String get roleServant;

  /// No description provided for @roleServantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage class, grades & attendance'**
  String get roleServantSubtitle;

  /// No description provided for @roleSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select your role to continue'**
  String get roleSelectPrompt;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get navAttendance;

  /// No description provided for @navGrades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get navGrades;

  /// No description provided for @navCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get navCommunication;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @commonBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get commonBackToHome;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get commonHigh;

  /// No description provided for @commonMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get commonMedium;

  /// No description provided for @commonLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get commonLow;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @commonTryChangingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try changing the filters.'**
  String get commonTryChangingFilters;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonPrev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get commonPrev;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get commonPending;

  /// No description provided for @commonQuestionShort.
  ///
  /// In en, this message translates to:
  /// **'Q{number}'**
  String commonQuestionShort(Object number);

  /// No description provided for @commonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @commonYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonYou;

  /// No description provided for @commonAddDate.
  ///
  /// In en, this message translates to:
  /// **'Add date'**
  String get commonAddDate;

  /// No description provided for @commonNa.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get commonNa;

  /// No description provided for @commonNoSubjectsForGrade.
  ///
  /// In en, this message translates to:
  /// **'No subjects found for your grade.'**
  String get commonNoSubjectsForGrade;

  /// No description provided for @commonWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'⚠️ {message}'**
  String commonWarningMessage(Object message);

  /// No description provided for @commonSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get commonSignOut;

  /// No description provided for @profileAccountDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get profileAccountDetailsSubtitle;

  /// No description provided for @profileLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get profileLoadFailedTitle;

  /// No description provided for @profileNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get profileNotAssigned;

  /// No description provided for @profileAcademicIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Academic ID'**
  String get profileAcademicIdLabel;

  /// No description provided for @profileGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get profileGradeLabel;

  /// No description provided for @profileAccountStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get profileAccountStatusLabel;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRoleLabel;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePassword;

  /// No description provided for @profileChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password for your account'**
  String get profileChangePasswordSubtitle;

  /// No description provided for @accountStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountStatusActive;

  /// No description provided for @accountStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get accountStatusInactive;

  /// No description provided for @accountStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get accountStatusSuspended;

  /// No description provided for @accountStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get accountStatusDisabled;

  /// No description provided for @servantGradesDeleteAssessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete assessment?'**
  String get servantGradesDeleteAssessmentTitle;

  /// No description provided for @servantGradesDeleteAssessmentBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String servantGradesDeleteAssessmentBody(Object name);

  /// No description provided for @servantGradesDeleteAssessmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete assessment.'**
  String get servantGradesDeleteAssessmentFailed;

  /// No description provided for @servantGradesFillRequiredFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields.'**
  String get servantGradesFillRequiredFieldsError;

  /// No description provided for @servantGradesWeightRangeError.
  ///
  /// In en, this message translates to:
  /// **'Weight must be between 0 and 100.'**
  String get servantGradesWeightRangeError;

  /// No description provided for @servantGradesInvalidScore.
  ///
  /// In en, this message translates to:
  /// **'Invalid score for {student}. Must be 0-{maxScore}.'**
  String servantGradesInvalidScore(Object maxScore, Object student);

  /// No description provided for @servantGradesAssessmentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Assessment updated.'**
  String get servantGradesAssessmentUpdated;

  /// No description provided for @servantGradesAssessmentAdded.
  ///
  /// In en, this message translates to:
  /// **'Assessment added.'**
  String get servantGradesAssessmentAdded;

  /// No description provided for @servantGradesSaveAssessmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save assessment.'**
  String get servantGradesSaveAssessmentFailed;

  /// No description provided for @servantGradesSubjectNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Subject name is required.'**
  String get servantGradesSubjectNameRequired;

  /// No description provided for @servantGradesSubjectAdded.
  ///
  /// In en, this message translates to:
  /// **'Subject added.'**
  String get servantGradesSubjectAdded;

  /// No description provided for @servantGradesSubjectAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add subject.'**
  String get servantGradesSubjectAddFailed;

  /// No description provided for @servantGradesAddNewAssessment.
  ///
  /// In en, this message translates to:
  /// **'Add New Assessment'**
  String get servantGradesAddNewAssessment;

  /// No description provided for @servantGradesHideGrades.
  ///
  /// In en, this message translates to:
  /// **'Hide Grades'**
  String get servantGradesHideGrades;

  /// No description provided for @servantGradesAllGrades.
  ///
  /// In en, this message translates to:
  /// **'All Grades'**
  String get servantGradesAllGrades;

  /// No description provided for @servantGradesMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get servantGradesMissing;

  /// No description provided for @servantGradesTotalWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Weight:'**
  String get servantGradesTotalWeightLabel;

  /// No description provided for @servantGradesTotalWeightExceeds.
  ///
  /// In en, this message translates to:
  /// **'Total weight exceeds 100%'**
  String get servantGradesTotalWeightExceeds;

  /// No description provided for @servantGradesRemainingToReach100.
  ///
  /// In en, this message translates to:
  /// **'{remaining}% remaining to reach 100%'**
  String servantGradesRemainingToReach100(Object remaining);

  /// No description provided for @servantGradesAddAssessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Assessment'**
  String get servantGradesAddAssessmentTitle;

  /// No description provided for @servantGradesEditAssessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Assessment'**
  String get servantGradesEditAssessmentTitle;

  /// No description provided for @servantGradesClassAvgLabel.
  ///
  /// In en, this message translates to:
  /// **'Class Avg: {percent}%'**
  String servantGradesClassAvgLabel(Object percent);

  /// No description provided for @servantGradesStudentScoresOptional.
  ///
  /// In en, this message translates to:
  /// **'Student Scores (Optional)'**
  String get servantGradesStudentScoresOptional;

  /// No description provided for @servantGradesSearchStudentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search students...'**
  String get servantGradesSearchStudentsHint;

  /// No description provided for @servantGradesPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {current} / {total}'**
  String servantGradesPageLabel(Object current, Object total);

  /// No description provided for @servantGradesScoreHint.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get servantGradesScoreHint;

  /// No description provided for @servantGradesAddSubjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Subject'**
  String get servantGradesAddSubjectTitle;

  /// No description provided for @servantGradesSubjectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Subject name (e.g., Theology)'**
  String get servantGradesSubjectNameHint;

  /// No description provided for @servantGradesManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Grades'**
  String get servantGradesManageTitle;

  /// No description provided for @servantGradesNewSubjectChip.
  ///
  /// In en, this message translates to:
  /// **'New Subject'**
  String get servantGradesNewSubjectChip;

  /// No description provided for @servantGradesWeightedTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Weighted Grades - {subjectName}'**
  String servantGradesWeightedTitle(Object subjectName);

  /// No description provided for @servantGradesWeightedBasedOn.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{Based on 1 assessment with {totalWeight}% total weight} other{Based on {count} assessments with {totalWeight}% total weight}}'**
  String servantGradesWeightedBasedOn(num count, Object totalWeight);

  /// No description provided for @servantGradesWeightedSearchByStudentNameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by student name...'**
  String get servantGradesWeightedSearchByStudentNameHint;

  /// No description provided for @servantGradesWeightedStudentNameHeader.
  ///
  /// In en, this message translates to:
  /// **'Student Name'**
  String get servantGradesWeightedStudentNameHeader;

  /// No description provided for @servantGradesWeightedScoreHeader.
  ///
  /// In en, this message translates to:
  /// **'Weighted Score'**
  String get servantGradesWeightedScoreHeader;

  /// No description provided for @servantGradesWeightedGradeHeader.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get servantGradesWeightedGradeHeader;

  /// No description provided for @servantGradesWeightedClassAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Class Average'**
  String get servantGradesWeightedClassAverageLabel;

  /// No description provided for @servantGradesWeightedHighestLabel.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get servantGradesWeightedHighestLabel;

  /// No description provided for @servantGradesWeightedLowestLabel.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get servantGradesWeightedLowestLabel;

  /// No description provided for @servantGradesMissingLabel.
  ///
  /// In en, this message translates to:
  /// **'Missing:'**
  String get servantGradesMissingLabel;

  /// No description provided for @servantGradesIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get servantGradesIncomplete;

  /// No description provided for @servantGradesMissingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} missing'**
  String servantGradesMissingCount(Object count);

  /// No description provided for @servantGradesMaxPoints.
  ///
  /// In en, this message translates to:
  /// **'Max: {maxScore} points'**
  String servantGradesMaxPoints(Object maxScore);

  /// No description provided for @servantGradesEditGradesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit grades'**
  String get servantGradesEditGradesTooltip;

  /// No description provided for @servantGradesDeleteAssessmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete assessment'**
  String get servantGradesDeleteAssessmentTooltip;

  /// No description provided for @servantGradesClassAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Class average'**
  String get servantGradesClassAverageLabel;

  /// No description provided for @servantGradesHideStudentScores.
  ///
  /// In en, this message translates to:
  /// **'Hide Student Scores'**
  String get servantGradesHideStudentScores;

  /// No description provided for @servantGradesViewStudentScores.
  ///
  /// In en, this message translates to:
  /// **'View Student Scores'**
  String get servantGradesViewStudentScores;

  /// No description provided for @servantGradesNoAssessmentsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No assessments yet'**
  String get servantGradesNoAssessmentsYetTitle;

  /// No description provided for @servantGradesNoAssessmentsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Add an assessment to start tracking student scores for this subject.'**
  String get servantGradesNoAssessmentsYetBody;

  /// No description provided for @servantGradesAssessmentNameHint.
  ///
  /// In en, this message translates to:
  /// **'Assessment name (e.g., Quiz 1)'**
  String get servantGradesAssessmentNameHint;

  /// No description provided for @servantGradesMaxScoreHint.
  ///
  /// In en, this message translates to:
  /// **'Max score'**
  String get servantGradesMaxScoreHint;

  /// No description provided for @servantGradesWeightPercentOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Weight % (optional)'**
  String get servantGradesWeightPercentOptionalHint;

  /// No description provided for @authStudentLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Login'**
  String get authStudentLoginTitle;

  /// No description provided for @authServantLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Servant Login'**
  String get authServantLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to continue'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordLabel;

  /// No description provided for @authNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get authNewPasswordHint;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authEmailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authEmailRequiredError;

  /// No description provided for @authPasswordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequiredError;

  /// No description provided for @authConfirmPasswordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authConfirmPasswordRequiredError;

  /// No description provided for @authPasswordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatchError;

  /// No description provided for @authPasswordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String authPasswordMinLengthError(Object min);

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginButton;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authForgotPassword;

  /// No description provided for @authForgotPasswordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get authForgotPasswordDialogTitle;

  /// No description provided for @authForgotPasswordDialogBody.
  ///
  /// In en, this message translates to:
  /// **'To change your password, please contact your class admin.'**
  String get authForgotPasswordDialogBody;

  /// No description provided for @authDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: use any valid email & password\nwhile backend is being wired fully.'**
  String get authDemoMode;

  /// No description provided for @authInvalidCredentialsError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authInvalidCredentialsError;

  /// No description provided for @authLoginFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get authLoginFailedGeneric;

  /// No description provided for @authRoleMismatchStudent.
  ///
  /// In en, this message translates to:
  /// **'This account is not a student account. Please select Servant role to continue.'**
  String get authRoleMismatchStudent;

  /// No description provided for @authRoleMismatchServant.
  ///
  /// In en, this message translates to:
  /// **'This account is not a servant account. Please select Student role to continue.'**
  String get authRoleMismatchServant;

  /// No description provided for @authRoleVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your account role. Please try again.'**
  String get authRoleVerificationFailed;

  /// No description provided for @authPasswordUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get authPasswordUpdateSuccess;

  /// No description provided for @authPasswordUpdateFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not update password. Please try again.'**
  String get authPasswordUpdateFailedGeneric;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get dashboardWelcome;

  /// No description provided for @dashboardAttendanceStat.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get dashboardAttendanceStat;

  /// No description provided for @dashboardAverageScoreStat.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get dashboardAverageScoreStat;

  /// No description provided for @dashboardCommunicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get dashboardCommunicationTitle;

  /// No description provided for @dashboardPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String dashboardPendingCount(Object count);

  /// No description provided for @dashboardPendingQuestions.
  ///
  /// In en, this message translates to:
  /// **'Pending Questions'**
  String get dashboardPendingQuestions;

  /// No description provided for @dashboardOpenComplaints.
  ///
  /// In en, this message translates to:
  /// **'Open Complaints'**
  String get dashboardOpenComplaints;

  /// No description provided for @dashboardGoToCommunication.
  ///
  /// In en, this message translates to:
  /// **'Go to Communication'**
  String get dashboardGoToCommunication;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardViewGrades.
  ///
  /// In en, this message translates to:
  /// **'View Grades'**
  String get dashboardViewGrades;

  /// No description provided for @studentDashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load dashboard data. Please try again.'**
  String get studentDashboardLoadFailed;

  /// No description provided for @attendanceTrackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your class participation'**
  String get attendanceTrackSubtitle;

  /// No description provided for @attendanceOverallTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall Attendance'**
  String get attendanceOverallTitle;

  /// No description provided for @attendanceAcrossAllSubjects.
  ///
  /// In en, this message translates to:
  /// **'across all subjects'**
  String get attendanceAcrossAllSubjects;

  /// No description provided for @attendanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load attendance. Please try again.'**
  String get attendanceLoadFailed;

  /// No description provided for @attendancePercentLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% attendance'**
  String attendancePercentLabel(Object percent);

  /// No description provided for @attendancePresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresent;

  /// No description provided for @attendanceLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceLate;

  /// No description provided for @attendanceAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsent;

  /// No description provided for @attendancePermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get attendancePermission;

  /// No description provided for @attendancePerformanceExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent attendance!'**
  String get attendancePerformanceExcellent;

  /// No description provided for @attendancePerformanceGreat.
  ///
  /// In en, this message translates to:
  /// **'Great attendance!'**
  String get attendancePerformanceGreat;

  /// No description provided for @attendancePerformanceGood.
  ///
  /// In en, this message translates to:
  /// **'Good attendance'**
  String get attendancePerformanceGood;

  /// No description provided for @attendancePerformanceNeedsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Attendance needs improvement'**
  String get attendancePerformanceNeedsImprovement;

  /// No description provided for @attendanceHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistoryTitle;

  /// No description provided for @attendanceSessionsRecorded.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions recorded'**
  String attendanceSessionsRecorded(Object count);

  /// No description provided for @attendanceNoRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No attendance records yet'**
  String get attendanceNoRecordsYet;

  /// No description provided for @attendanceImproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Improve Your Attendance'**
  String get attendanceImproveTitle;

  /// No description provided for @attendanceImproveBody.
  ///
  /// In en, this message translates to:
  /// **'Regular attendance is important for your learning and promotion. Try to attend all classes and arrive on time.'**
  String get attendanceImproveBody;

  /// No description provided for @servantAttendanceChooseSubjectAndDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a subject and a date'**
  String get servantAttendanceChooseSubjectAndDate;

  /// No description provided for @servantAttendanceMinimumDaysAbsent.
  ///
  /// In en, this message translates to:
  /// **'Minimum days absent'**
  String get servantAttendanceMinimumDaysAbsent;

  /// No description provided for @servantAttendanceMinAbsentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter minimum absent days'**
  String get servantAttendanceMinAbsentHint;

  /// No description provided for @servantAttendanceStudentsAbsentAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Students absent for at least {days} day(s):'**
  String servantAttendanceStudentsAbsentAtLeast(Object days);

  /// No description provided for @servantAttendanceNoStudentsMatch.
  ///
  /// In en, this message translates to:
  /// **'No students match.'**
  String get servantAttendanceNoStudentsMatch;

  /// No description provided for @servantAttendanceAbsentDays.
  ///
  /// In en, this message translates to:
  /// **'{days} absent'**
  String servantAttendanceAbsentDays(Object days);

  /// No description provided for @servantAttendancePreviousDates.
  ///
  /// In en, this message translates to:
  /// **'Previous dates'**
  String get servantAttendancePreviousDates;

  /// No description provided for @servantAttendanceNoDatesYet.
  ///
  /// In en, this message translates to:
  /// **'No attendance dates yet.'**
  String get servantAttendanceNoDatesYet;

  /// No description provided for @servantAttendanceSearchStudentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search students'**
  String get servantAttendanceSearchStudentsHint;

  /// No description provided for @servantAttendanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load attendance data. Please try again.'**
  String get servantAttendanceLoadFailed;

  /// No description provided for @servantAttendanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved'**
  String get servantAttendanceSaved;

  /// No description provided for @servantAttendanceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save attendance'**
  String get servantAttendanceSaveFailed;

  /// No description provided for @commAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get commAnnouncements;

  /// No description provided for @commQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get commQuestions;

  /// No description provided for @commComplaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get commComplaints;

  /// No description provided for @commFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get commFeedback;

  /// No description provided for @servantCommSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements, questions, complaints, and feedback.'**
  String get servantCommSubtitle;

  /// No description provided for @commNoAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'No announcements'**
  String get commNoAnnouncements;

  /// No description provided for @commAnnouncementsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check back later for updates'**
  String get commAnnouncementsEmptySubtitle;

  /// No description provided for @commAnnouncementsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load announcements.'**
  String get commAnnouncementsLoadFailed;

  /// No description provided for @commLoadQuestionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load questions.'**
  String get commLoadQuestionsFailed;

  /// No description provided for @commLoadComplaintsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load complaints.'**
  String get commLoadComplaintsFailed;

  /// No description provided for @commLoadFeedbackFormsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feedback forms.'**
  String get commLoadFeedbackFormsFailed;

  /// No description provided for @commLoadContextFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load required information. Please try again.'**
  String get commLoadContextFailed;

  /// No description provided for @commSubmitQuestionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit question. Please try again.'**
  String get commSubmitQuestionFailed;

  /// No description provided for @commSubmitComplaintFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit complaint. Please try again.'**
  String get commSubmitComplaintFailed;

  /// No description provided for @commSubmitFeedbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit feedback. Please try again.'**
  String get commSubmitFeedbackFailed;

  /// No description provided for @servantCommLoadQuestionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load questions.'**
  String get servantCommLoadQuestionsFailed;

  /// No description provided for @servantCommLoadComplaintsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load complaints.'**
  String get servantCommLoadComplaintsFailed;

  /// No description provided for @servantCommSendResponseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send response. Please try again.'**
  String get servantCommSendResponseFailed;

  /// No description provided for @servantCommUpdateComplaintFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update complaint. Please try again.'**
  String get servantCommUpdateComplaintFailed;

  /// No description provided for @commAnnouncementCategoryUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get commAnnouncementCategoryUrgent;

  /// No description provided for @commAnnouncementCategoryGrades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get commAnnouncementCategoryGrades;

  /// No description provided for @commAnnouncementCategorySchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get commAnnouncementCategorySchedule;

  /// No description provided for @commAnnouncementCategoryEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get commAnnouncementCategoryEvent;

  /// No description provided for @commAnnouncementCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get commAnnouncementCategoryGeneral;

  /// No description provided for @commPostedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by {name}'**
  String commPostedBy(Object name);

  /// No description provided for @commAskQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a Question'**
  String get commAskQuestion;

  /// No description provided for @commPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get commPending;

  /// No description provided for @commAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get commAnswered;

  /// No description provided for @commInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get commInReview;

  /// No description provided for @commResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get commResolved;

  /// No description provided for @commNoQuestionsYet.
  ///
  /// In en, this message translates to:
  /// **'No questions yet'**
  String get commNoQuestionsYet;

  /// No description provided for @commResponseLabel.
  ///
  /// In en, this message translates to:
  /// **'Response:'**
  String get commResponseLabel;

  /// No description provided for @servantCommNoComplaints.
  ///
  /// In en, this message translates to:
  /// **'No complaints'**
  String get servantCommNoComplaints;

  /// No description provided for @servantCommRespond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get servantCommRespond;

  /// No description provided for @servantCommTypeResponseHint.
  ///
  /// In en, this message translates to:
  /// **'Type your response...'**
  String get servantCommTypeResponseHint;

  /// No description provided for @servantCommEnterResponseError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a response.'**
  String get servantCommEnterResponseError;

  /// No description provided for @servantCommSavedLocallySyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved locally; sync failed.'**
  String get servantCommSavedLocallySyncFailed;

  /// No description provided for @servantCommSendResponse.
  ///
  /// In en, this message translates to:
  /// **'Send response'**
  String get servantCommSendResponse;

  /// No description provided for @servantCommDeleteQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete question?'**
  String get servantCommDeleteQuestionTitle;

  /// No description provided for @servantCommDeleteQuestionBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this question.'**
  String get servantCommDeleteQuestionBody;

  /// No description provided for @servantCommDeleteQuestionPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You may not have permission to delete questions.'**
  String get servantCommDeleteQuestionPermissionDenied;

  /// No description provided for @servantCommDeleteComplaintTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete complaint?'**
  String get servantCommDeleteComplaintTitle;

  /// No description provided for @servantCommDeleteComplaintBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this complaint.'**
  String get servantCommDeleteComplaintBody;

  /// No description provided for @servantCommDeleteFromServerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete from server.'**
  String get servantCommDeleteFromServerFailed;

  /// No description provided for @commSubjectBibleStudies.
  ///
  /// In en, this message translates to:
  /// **'Bible Studies'**
  String get commSubjectBibleStudies;

  /// No description provided for @commSubjectChristianHistory.
  ///
  /// In en, this message translates to:
  /// **'Christian History'**
  String get commSubjectChristianHistory;

  /// No description provided for @commSubjectGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get commSubjectGeneral;

  /// No description provided for @commSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get commSubjectLabel;

  /// No description provided for @commYourQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Question'**
  String get commYourQuestionLabel;

  /// No description provided for @commQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question here...'**
  String get commQuestionHint;

  /// No description provided for @commSelectSubjectError.
  ///
  /// In en, this message translates to:
  /// **'Please select a subject'**
  String get commSelectSubjectError;

  /// No description provided for @commEnterQuestionError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your question'**
  String get commEnterQuestionError;

  /// No description provided for @commQuestionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Question submitted!'**
  String get commQuestionSubmitted;

  /// No description provided for @commSubmitComplaint.
  ///
  /// In en, this message translates to:
  /// **'Submit Complaint'**
  String get commSubmitComplaint;

  /// No description provided for @commNoComplaintsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'No complaints submitted'**
  String get commNoComplaintsSubmitted;

  /// No description provided for @commCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get commCategoryLabel;

  /// No description provided for @commCategoryTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get commCategoryTeacher;

  /// No description provided for @commCategoryFacility.
  ///
  /// In en, this message translates to:
  /// **'Facility'**
  String get commCategoryFacility;

  /// No description provided for @commCategoryCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get commCategoryCourse;

  /// No description provided for @commCategoryAdministrative.
  ///
  /// In en, this message translates to:
  /// **'Administrative'**
  String get commCategoryAdministrative;

  /// No description provided for @commCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get commCategoryOther;

  /// No description provided for @commSelectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get commSelectCategoryError;

  /// No description provided for @commTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get commTitleLabel;

  /// No description provided for @commComplaintTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Brief title for your complaint'**
  String get commComplaintTitleHint;

  /// No description provided for @commEnterTitleError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get commEnterTitleError;

  /// No description provided for @commDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commDescriptionLabel;

  /// No description provided for @commComplaintDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your complaint in detail...'**
  String get commComplaintDescriptionHint;

  /// No description provided for @commEnterDescriptionError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get commEnterDescriptionError;

  /// No description provided for @commSubmitAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Submit anonymously'**
  String get commSubmitAnonymously;

  /// No description provided for @commComplaintSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Complaint submitted!'**
  String get commComplaintSubmitted;

  /// No description provided for @commNoActiveFeedbackForms.
  ///
  /// In en, this message translates to:
  /// **'No active feedback forms'**
  String get commNoActiveFeedbackForms;

  /// No description provided for @commFeedbackEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your servant may share feedback forms in the future. Check back later.'**
  String get commFeedbackEmptySubtitle;

  /// No description provided for @bootstrapErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'App startup failed'**
  String get bootstrapErrorTitle;

  /// No description provided for @bootstrapErrorFix.
  ///
  /// In en, this message translates to:
  /// **'Fix: check your internet connection and try again.'**
  String get bootstrapErrorFix;

  /// No description provided for @bootstrapErrorVerifyPath.
  ///
  /// In en, this message translates to:
  /// **'If the problem persists, contact your administrator.'**
  String get bootstrapErrorVerifyPath;

  /// No description provided for @servantDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Servant Dashboard'**
  String get servantDashboardTitle;

  /// No description provided for @servantDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Class Management'**
  String get servantDashboardSubtitle;

  /// No description provided for @servantDashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load dashboard data. Please try again.'**
  String get servantDashboardLoadFailed;

  /// No description provided for @servantTotalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get servantTotalStudents;

  /// No description provided for @servantDashboardAvgAttendanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Attendance'**
  String get servantDashboardAvgAttendanceLabel;

  /// No description provided for @servantDashboardPendingItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending Items'**
  String get servantDashboardPendingItemsLabel;

  /// No description provided for @servantDashboardQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get servantDashboardQuickActionsTitle;

  /// No description provided for @servantDashboardMarkAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark Attendance'**
  String get servantDashboardMarkAttendanceTitle;

  /// No description provided for @servantDashboardMarkAttendanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record today\'s attendance'**
  String get servantDashboardMarkAttendanceSubtitle;

  /// No description provided for @servantDashboardAddGradesTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Grades'**
  String get servantDashboardAddGradesTitle;

  /// No description provided for @servantDashboardAddGradesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter or update student grades'**
  String get servantDashboardAddGradesSubtitle;

  /// No description provided for @servantRegisterStudentQuickActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Student'**
  String get servantRegisterStudentQuickActionTitle;

  /// No description provided for @servantRegisterStudentQuickActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new student to a grade'**
  String get servantRegisterStudentQuickActionSubtitle;

  /// No description provided for @servantRegisterStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Student'**
  String get servantRegisterStudentTitle;

  /// No description provided for @servantRegisterStudentFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Student full name'**
  String get servantRegisterStudentFullNameLabel;

  /// No description provided for @servantRegisterStudentFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., John Doe'**
  String get servantRegisterStudentFullNameHint;

  /// No description provided for @servantRegisterStudentGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Registering grade'**
  String get servantRegisterStudentGradeLabel;

  /// No description provided for @servantRegisterStudentNoGradesMessage.
  ///
  /// In en, this message translates to:
  /// **'No grades found. Please contact your class admin.'**
  String get servantRegisterStudentNoGradesMessage;

  /// No description provided for @servantRegisterStudentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get servantRegisterStudentSubmit;

  /// No description provided for @servantRegisterStudentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the student\'s full name'**
  String get servantRegisterStudentNameRequired;

  /// No description provided for @servantRegisterStudentGradeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a grade'**
  String get servantRegisterStudentGradeRequired;

  /// No description provided for @servantRegisterStudentFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not register student. Please try again.'**
  String get servantRegisterStudentFailedGeneric;

  /// No description provided for @servantRegisterStudentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Student registered'**
  String get servantRegisterStudentSuccessTitle;

  /// No description provided for @servantRegisterStudentSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Academic ID: {academicId}\nInitial password: same as Academic ID'**
  String servantRegisterStudentSuccessMessage(Object academicId);

  /// No description provided for @servantDashboardGradeAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Performance insights & trends'**
  String get servantDashboardGradeAnalyticsSubtitle;

  /// No description provided for @servantDashboardTodayScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get servantDashboardTodayScheduleTitle;

  /// No description provided for @servantDashboardSundaySchoolClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunday School Class'**
  String get servantDashboardSundaySchoolClassTitle;

  /// No description provided for @servantDashboardSundaySchoolClassTime.
  ///
  /// In en, this message translates to:
  /// **'9:00 AM - 10:30 AM'**
  String get servantDashboardSundaySchoolClassTime;

  /// No description provided for @servantDashboardBibleStudyReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Bible Study Review'**
  String get servantDashboardBibleStudyReviewTitle;

  /// No description provided for @servantDashboardBibleStudyReviewTime.
  ///
  /// In en, this message translates to:
  /// **'10:30 AM - 11:00 AM'**
  String get servantDashboardBibleStudyReviewTime;

  /// No description provided for @servantDashboardPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'{qCount,plural,=1{You have 1 question} other{You have {qCount} questions}} and {cCount,plural,=1{1 complaint} other{{cCount} complaints}} pending'**
  String servantDashboardPendingMessage(num cCount, num qCount);

  /// No description provided for @servantDashboardViewButton.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get servantDashboardViewButton;

  /// No description provided for @servantAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Grade Analytics'**
  String get servantAnalyticsTitle;

  /// No description provided for @servantAnalyticsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load analytics.'**
  String get servantAnalyticsLoadFailed;

  /// No description provided for @servantAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Performance Insights & Trends'**
  String get servantAnalyticsSubtitle;

  /// No description provided for @servantAnalyticsTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get servantAnalyticsTabOverview;

  /// No description provided for @servantAnalyticsTabBySubject.
  ///
  /// In en, this message translates to:
  /// **'By Subject'**
  String get servantAnalyticsTabBySubject;

  /// No description provided for @servantAnalyticsTabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get servantAnalyticsTabStudents;

  /// No description provided for @servantAnalyticsMetricClassAverage.
  ///
  /// In en, this message translates to:
  /// **'Class Average'**
  String get servantAnalyticsMetricClassAverage;

  /// No description provided for @servantAnalyticsStudentsWithGradesLabel.
  ///
  /// In en, this message translates to:
  /// **'{graded}/{total} students'**
  String servantAnalyticsStudentsWithGradesLabel(Object graded, Object total);

  /// No description provided for @servantAnalyticsMetricAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At-Risk'**
  String get servantAnalyticsMetricAtRisk;

  /// No description provided for @servantAnalyticsAtRiskPercentOfClass.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of class'**
  String servantAnalyticsAtRiskPercentOfClass(Object percent);

  /// No description provided for @servantAnalyticsMetricTopPerformers.
  ///
  /// In en, this message translates to:
  /// **'Top Performers'**
  String get servantAnalyticsMetricTopPerformers;

  /// No description provided for @servantAnalyticsTopPerformersThreshold.
  ///
  /// In en, this message translates to:
  /// **'Students ≥ 90%'**
  String get servantAnalyticsTopPerformersThreshold;

  /// No description provided for @servantAnalyticsMetricMissingWork.
  ///
  /// In en, this message translates to:
  /// **'Missing Work'**
  String get servantAnalyticsMetricMissingWork;

  /// No description provided for @servantAnalyticsMissingWorkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Students incomplete'**
  String get servantAnalyticsMissingWorkSubtitle;

  /// No description provided for @servantAnalyticsGradeDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Grade Distribution'**
  String get servantAnalyticsGradeDistributionTitle;

  /// No description provided for @servantAnalyticsSubjectPerformanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Subject Performance'**
  String get servantAnalyticsSubjectPerformanceTitle;

  /// No description provided for @servantAnalyticsPerformanceByAssessmentTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance by Assessment Type'**
  String get servantAnalyticsPerformanceByAssessmentTypeTitle;

  /// No description provided for @servantAnalyticsKeyInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Insights'**
  String get servantAnalyticsKeyInsightsTitle;

  /// No description provided for @servantAnalyticsNoInsightsYet.
  ///
  /// In en, this message translates to:
  /// **'No insights yet.'**
  String get servantAnalyticsNoInsightsYet;

  /// No description provided for @servantAnalyticsInsightClassPerformingWell.
  ///
  /// In en, this message translates to:
  /// **'Class is performing well with an average of 80%+'**
  String get servantAnalyticsInsightClassPerformingWell;

  /// No description provided for @servantAnalyticsInsightAtRiskStudents.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 student needs additional support (below 70%)} other{{count} students need additional support (below 70%)}}'**
  String servantAnalyticsInsightAtRiskStudents(num count);

  /// No description provided for @servantAnalyticsInsightIncompleteAssessments.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 student has incomplete assessments} other{{count} students have incomplete assessments}}'**
  String servantAnalyticsInsightIncompleteAssessments(num count);

  /// No description provided for @servantAnalyticsInsightTopPerformers.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 student is excelling (top 1)} other{{count} students are excelling (top {count})}}'**
  String servantAnalyticsInsightTopPerformers(num count);

  /// No description provided for @servantAnalyticsSelectSubjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a Subject'**
  String get servantAnalyticsSelectSubjectTitle;

  /// No description provided for @servantAnalyticsHighestLabel.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get servantAnalyticsHighestLabel;

  /// No description provided for @servantAnalyticsLowestLabel.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get servantAnalyticsLowestLabel;

  /// No description provided for @servantAnalyticsIncompleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get servantAnalyticsIncompleteLabel;

  /// No description provided for @servantAnalyticsBackToSubjects.
  ///
  /// In en, this message translates to:
  /// **'Back to Subjects'**
  String get servantAnalyticsBackToSubjects;

  /// No description provided for @servantAnalyticsAssessmentBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment Breakdown'**
  String get servantAnalyticsAssessmentBreakdownTitle;

  /// No description provided for @servantAnalyticsCompletedOutOf.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} completed'**
  String servantAnalyticsCompletedOutOf(Object completed, Object total);

  /// No description provided for @servantAnalyticsTopPerformersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Students with highest averages'**
  String get servantAnalyticsTopPerformersSubtitle;

  /// No description provided for @servantAnalyticsStudentsNeedingSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Students Needing Support'**
  String get servantAnalyticsStudentsNeedingSupportTitle;

  /// No description provided for @servantAnalyticsStudentsNeedingSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Below 70% average - requires attention'**
  String get servantAnalyticsStudentsNeedingSupportSubtitle;

  /// No description provided for @servantAnalyticsNeedsHelp.
  ///
  /// In en, this message translates to:
  /// **'Needs help'**
  String get servantAnalyticsNeedsHelp;

  /// No description provided for @servantAnalyticsIncompleteAssessmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Incomplete Assessments'**
  String get servantAnalyticsIncompleteAssessmentsTitle;

  /// No description provided for @servantAnalyticsIncompleteAssessmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Students with missing work'**
  String get servantAnalyticsIncompleteAssessmentsSubtitle;

  /// No description provided for @servantAnalyticsSubjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{subject} other{subjects}}'**
  String servantAnalyticsSubjectsLabel(num count);

  /// No description provided for @servantAnalyticsAndMore.
  ///
  /// In en, this message translates to:
  /// **'And {count} more...'**
  String servantAnalyticsAndMore(Object count);

  /// No description provided for @servantAnalyticsNoStudentsToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No students to display.'**
  String get servantAnalyticsNoStudentsToDisplay;

  /// No description provided for @studentFinalResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Final Results'**
  String get studentFinalResultsTitle;

  /// No description provided for @studentGradesAcademicYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Academic Year {yearName}'**
  String studentGradesAcademicYearLabel(Object yearName);

  /// No description provided for @studentFinalResultsFinalGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Final Grade'**
  String get studentFinalResultsFinalGradeLabel;

  /// No description provided for @studentFinalResultsPromotionStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Promotion Status'**
  String get studentFinalResultsPromotionStatusLabel;

  /// No description provided for @studentFinalResultsPromotionPromotedTitle.
  ///
  /// In en, this message translates to:
  /// **'Promoted'**
  String get studentFinalResultsPromotionPromotedTitle;

  /// No description provided for @studentFinalResultsPromotionPromotedMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You have been promoted to the next grade.'**
  String get studentFinalResultsPromotionPromotedMessage;

  /// No description provided for @studentFinalResultsPromotionAtRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'At Risk'**
  String get studentFinalResultsPromotionAtRiskTitle;

  /// No description provided for @studentFinalResultsPromotionAtRiskMessage.
  ///
  /// In en, this message translates to:
  /// **'You are at risk of not being promoted. Please consult with your teacher.'**
  String get studentFinalResultsPromotionAtRiskMessage;

  /// No description provided for @studentFinalResultsPromotionNotPromotedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Promoted'**
  String get studentFinalResultsPromotionNotPromotedTitle;

  /// No description provided for @studentFinalResultsPromotionNotPromotedMessage.
  ///
  /// In en, this message translates to:
  /// **'You have not met the promotion requirements. Please consult with your teacher.'**
  String get studentFinalResultsPromotionNotPromotedMessage;

  /// No description provided for @studentFinalResultsFinalSubjectGradesTitle.
  ///
  /// In en, this message translates to:
  /// **'Final Subject Grades'**
  String get studentFinalResultsFinalSubjectGradesTitle;

  /// No description provided for @studentFinalResultsFinalSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Final Summary'**
  String get studentFinalResultsFinalSummaryTitle;

  /// No description provided for @studentGradesHighestGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Highest Grade'**
  String get studentGradesHighestGradeLabel;

  /// No description provided for @studentGradesLowestGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Lowest Grade'**
  String get studentGradesLowestGradeLabel;

  /// No description provided for @studentGradesOverallAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall Average'**
  String get studentGradesOverallAverageLabel;

  /// No description provided for @studentFinalResultsAcademicYearEndedMessage.
  ///
  /// In en, this message translates to:
  /// **'The academic year has ended. These are your final grades for {yearName}. Enjoy your break and we look forward to seeing you in the next academic year!'**
  String studentFinalResultsAcademicYearEndedMessage(Object yearName);

  /// No description provided for @studentGradesKeepUpExcellentWork.
  ///
  /// In en, this message translates to:
  /// **'Keep up the excellent work!'**
  String get studentGradesKeepUpExcellentWork;

  /// No description provided for @studentGradesAssessmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 assessment} other{{count} assessments}}'**
  String studentGradesAssessmentsCount(num count);

  /// No description provided for @studentGradesAssessmentBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment Breakdown'**
  String get studentGradesAssessmentBreakdownTitle;

  /// No description provided for @studentGradesMissingAssessmentsWarning.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{⚠️ You are missing 1 assessment in this subject. Your grade is calculated based only on completed assessments.} other{⚠️ You are missing {count} assessments in this subject. Your grade is calculated based only on completed assessments.}}'**
  String studentGradesMissingAssessmentsWarning(num count);

  /// No description provided for @studentGradesPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{score}/{maxScore} pts'**
  String studentGradesPointsLabel(Object maxScore, Object score);

  /// No description provided for @studentGradesPerformanceSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance Summary'**
  String get studentGradesPerformanceSummaryTitle;

  /// No description provided for @studentGradesTotalSubjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Subjects'**
  String get studentGradesTotalSubjectsLabel;

  /// No description provided for @gradesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load grades. Please try again.'**
  String get gradesLoadFailed;

  /// No description provided for @servantGradesLoadSubjectsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subjects.'**
  String get servantGradesLoadSubjectsFailed;

  /// No description provided for @servantGradesLoadStudentsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load students.'**
  String get servantGradesLoadStudentsFailed;

  /// No description provided for @servantGradesLoadGradeEntriesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load grade entries.'**
  String get servantGradesLoadGradeEntriesFailed;

  /// No description provided for @servantGradesLockedByAdminSettings.
  ///
  /// In en, this message translates to:
  /// **'Grade management is locked by admin settings.'**
  String get servantGradesLockedByAdminSettings;

  /// No description provided for @servantGradesThisAcademicYear.
  ///
  /// In en, this message translates to:
  /// **'this academic year'**
  String get servantGradesThisAcademicYear;

  /// No description provided for @servantGradesAcademicYearEndedLocked.
  ///
  /// In en, this message translates to:
  /// **'Academic year {yearName} has ended. Grade management is locked.'**
  String servantGradesAcademicYearEndedLocked(Object yearName);

  /// No description provided for @servantGradesLocked.
  ///
  /// In en, this message translates to:
  /// **'Grade management is locked.'**
  String get servantGradesLocked;

  /// No description provided for @servantGradesDefaultAssessmentType.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get servantGradesDefaultAssessmentType;

  /// No description provided for @servantGradesMissingAssessmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing Assessments - {subjectName}'**
  String servantGradesMissingAssessmentsTitle(Object subjectName);

  /// No description provided for @servantGradesStudentsWithIncompleteAssessments.
  ///
  /// In en, this message translates to:
  /// **'Students with incomplete assessments: {count}'**
  String servantGradesStudentsWithIncompleteAssessments(Object count);

  /// No description provided for @servantGradesNoMissingAssessmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No missing assessments found.'**
  String get servantGradesNoMissingAssessmentsFound;

  /// No description provided for @servantAnnouncementsEnterTitleAndMessageError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title and message.'**
  String get servantAnnouncementsEnterTitleAndMessageError;

  /// No description provided for @servantAnnouncementsPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to post announcement. Please try again.'**
  String get servantAnnouncementsPostFailed;

  /// No description provided for @servantAnnouncementsSavedLocallySyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved locally; sync failed.'**
  String get servantAnnouncementsSavedLocallySyncFailed;

  /// No description provided for @servantAnnouncementsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Announcement'**
  String get servantAnnouncementsCreateTitle;

  /// No description provided for @servantAnnouncementsCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get servantAnnouncementsCategoryLabel;

  /// No description provided for @servantAnnouncementsSelectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get servantAnnouncementsSelectCategoryHint;

  /// No description provided for @servantAnnouncementsTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get servantAnnouncementsTitleHint;

  /// No description provided for @servantAnnouncementsMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get servantAnnouncementsMessageLabel;

  /// No description provided for @servantAnnouncementsMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write your announcement...'**
  String get servantAnnouncementsMessageHint;

  /// No description provided for @servantAnnouncementsPostButton.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get servantAnnouncementsPostButton;

  /// No description provided for @servantAnnouncementsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet'**
  String get servantAnnouncementsEmptyTitle;

  /// No description provided for @servantAnnouncementsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an announcement to share updates with students.'**
  String get servantAnnouncementsEmptySubtitle;

  /// No description provided for @servantAnnouncementsReadCount.
  ///
  /// In en, this message translates to:
  /// **'{read} / {total} read'**
  String servantAnnouncementsReadCount(Object read, Object total);

  /// No description provided for @servantAnnouncementsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target: {audience}'**
  String servantAnnouncementsTarget(Object audience);

  /// No description provided for @servantAnnouncementsStudentsReadCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 student read} other{{count} students read}}'**
  String servantAnnouncementsStudentsReadCount(num count);

  /// No description provided for @servantAnnouncementsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete announcement?'**
  String get servantAnnouncementsDeleteTitle;

  /// No description provided for @servantAnnouncementsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete the announcement for everyone.'**
  String get servantAnnouncementsDeleteBody;

  /// No description provided for @servantAnnouncementsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete announcement.'**
  String get servantAnnouncementsDeleteFailed;

  /// No description provided for @profileErrorNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in.'**
  String get profileErrorNotSignedIn;

  /// No description provided for @profileErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found.'**
  String get profileErrorNotFound;

  /// No description provided for @servantFeedbackSelectTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get servantFeedbackSelectTypeTitle;

  /// No description provided for @servantFeedbackTypeTeacherEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Teacher Evaluation'**
  String get servantFeedbackTypeTeacherEvaluation;

  /// No description provided for @servantFeedbackTypeCourseEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Course Evaluation'**
  String get servantFeedbackTypeCourseEvaluation;

  /// No description provided for @servantFeedbackTypeSemesterEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Semester Evaluation'**
  String get servantFeedbackTypeSemesterEvaluation;

  /// No description provided for @servantFeedbackTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get servantFeedbackTypeGeneral;

  /// No description provided for @servantFeedbackCreateFormButton.
  ///
  /// In en, this message translates to:
  /// **'Create Feedback Form'**
  String get servantFeedbackCreateFormButton;

  /// No description provided for @servantFeedbackCreateFormSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Feedback form created successfully!'**
  String get servantFeedbackCreateFormSuccessToast;

  /// No description provided for @servantFeedbackLoadFormsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feedback forms.'**
  String get servantFeedbackLoadFormsFailed;

  /// No description provided for @servantFeedbackEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No feedback forms yet'**
  String get servantFeedbackEmptyTitle;

  /// No description provided for @servantFeedbackEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a form to collect student feedback'**
  String get servantFeedbackEmptySubtitle;

  /// No description provided for @servantFeedbackActiveFormsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Forms'**
  String get servantFeedbackActiveFormsLabel;

  /// No description provided for @servantFeedbackStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get servantFeedbackStatusActive;

  /// No description provided for @servantFeedbackStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get servantFeedbackStatusExpired;

  /// No description provided for @servantFeedbackQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 question} other{{count} questions}}'**
  String servantFeedbackQuestionsCount(num count);

  /// No description provided for @servantFeedbackDeleteFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Feedback Form?'**
  String get servantFeedbackDeleteFormTitle;

  /// No description provided for @servantFeedbackDeleteFormFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete feedback form.'**
  String get servantFeedbackDeleteFormFailed;

  /// No description provided for @servantFeedbackDeleteFormBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the form and all {responseCount} student responses. This action cannot be undone.'**
  String servantFeedbackDeleteFormBody(Object responseCount);

  /// No description provided for @servantFeedbackDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String servantFeedbackDueLabel(Object date);

  /// No description provided for @servantFeedbackResponsesCount.
  ///
  /// In en, this message translates to:
  /// **'{submitted}/{total} responses'**
  String servantFeedbackResponsesCount(Object submitted, Object total);

  /// No description provided for @servantFeedbackViewAnalyticsButton.
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get servantFeedbackViewAnalyticsButton;

  /// No description provided for @servantFeedbackCreateFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Feedback Form'**
  String get servantFeedbackCreateFormTitle;

  /// No description provided for @servantFeedbackCreateFormSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Create Form'**
  String get servantFeedbackCreateFormSubmitButton;

  /// No description provided for @servantFeedbackTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get servantFeedbackTitleLabel;

  /// No description provided for @servantFeedbackTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Mid-Semester Teacher Evaluation'**
  String get servantFeedbackTitleHint;

  /// No description provided for @servantFeedbackDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get servantFeedbackDescriptionLabel;

  /// No description provided for @servantFeedbackDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the feedback form'**
  String get servantFeedbackDescriptionHint;

  /// No description provided for @servantFeedbackTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get servantFeedbackTypeLabel;

  /// No description provided for @servantFeedbackStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start:'**
  String get servantFeedbackStartDateLabel;

  /// No description provided for @servantFeedbackEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End:'**
  String get servantFeedbackEndDateLabel;

  /// No description provided for @servantFeedbackQuestionsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get servantFeedbackQuestionsSectionTitle;

  /// No description provided for @servantFeedbackTextResponsesReceived.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=0{0 text responses received} =1{1 text response received} other{{count} text responses received}}'**
  String servantFeedbackTextResponsesReceived(num count);

  /// No description provided for @servantFeedbackQuestionsAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=0{0 questions added} =1{1 question added} other{{count} questions added}}'**
  String servantFeedbackQuestionsAddedCount(num count);

  /// No description provided for @servantFeedbackAddQuestionButton.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get servantFeedbackAddQuestionButton;

  /// No description provided for @servantFeedbackRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get servantFeedbackRequiredLabel;

  /// No description provided for @servantFeedbackNewQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'New Question'**
  String get servantFeedbackNewQuestionTitle;

  /// No description provided for @servantFeedbackQuestionTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Question Text'**
  String get servantFeedbackQuestionTextLabel;

  /// No description provided for @servantFeedbackQuestionTextHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your question...'**
  String get servantFeedbackQuestionTextHint;

  /// No description provided for @servantFeedbackQuestionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Question Type'**
  String get servantFeedbackQuestionTypeLabel;

  /// No description provided for @servantFeedbackQuestionTypeRating.
  ///
  /// In en, this message translates to:
  /// **'Rating (1-5)'**
  String get servantFeedbackQuestionTypeRating;

  /// No description provided for @servantFeedbackQuestionTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get servantFeedbackQuestionTypeText;

  /// No description provided for @servantFeedbackQuestionTypeMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get servantFeedbackQuestionTypeMultipleChoice;

  /// No description provided for @servantFeedbackRequiredQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Required?'**
  String get servantFeedbackRequiredQuestionLabel;

  /// No description provided for @servantFeedbackYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get servantFeedbackYes;

  /// No description provided for @servantFeedbackNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get servantFeedbackNo;

  /// No description provided for @servantFeedbackOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get servantFeedbackOptionsLabel;

  /// No description provided for @servantFeedbackOptionHint.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String servantFeedbackOptionHint(Object number);

  /// No description provided for @servantFeedbackAddOptionButton.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get servantFeedbackAddOptionButton;

  /// No description provided for @servantFeedbackMultipleChoiceNeedsTwoOptions.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice questions need at least 2 options.'**
  String get servantFeedbackMultipleChoiceNeedsTwoOptions;

  /// No description provided for @servantFeedbackFormNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Form not found'**
  String get servantFeedbackFormNotFoundTitle;

  /// No description provided for @servantFeedbackFormNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please go back and try again.'**
  String get servantFeedbackFormNotFoundSubtitle;

  /// No description provided for @servantFeedbackAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback Analytics'**
  String get servantFeedbackAnalyticsTitle;

  /// No description provided for @servantFeedbackQuestionsAndDueLine.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 question} other{{count} questions}} • Due: {date}'**
  String servantFeedbackQuestionsAndDueLine(num count, Object date);

  /// No description provided for @servantFeedbackSubmissionStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission Statistics'**
  String get servantFeedbackSubmissionStatisticsTitle;

  /// No description provided for @servantFeedbackSubmittedLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get servantFeedbackSubmittedLabel;

  /// No description provided for @servantFeedbackPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get servantFeedbackPendingLabel;

  /// No description provided for @servantFeedbackRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get servantFeedbackRateLabel;

  /// No description provided for @servantFeedbackNoResponsesTitle.
  ///
  /// In en, this message translates to:
  /// **'No responses yet'**
  String get servantFeedbackNoResponsesTitle;

  /// No description provided for @servantFeedbackNoResponsesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics will appear here as students submit feedback'**
  String get servantFeedbackNoResponsesSubtitle;

  /// No description provided for @servantFeedbackLoadResponsesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load responses.'**
  String get servantFeedbackLoadResponsesFailed;

  /// No description provided for @servantFeedbackAverageRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get servantFeedbackAverageRatingLabel;

  /// No description provided for @servantFeedbackDistributionLabel.
  ///
  /// In en, this message translates to:
  /// **'Distribution:'**
  String get servantFeedbackDistributionLabel;

  /// No description provided for @servantFeedbackResponsesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{1 response} other{{count} responses}}'**
  String servantFeedbackResponsesCountLabel(num count);

  /// No description provided for @servantFeedbackEnterTitleError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get servantFeedbackEnterTitleError;

  /// No description provided for @servantFeedbackEnterDescriptionError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description.'**
  String get servantFeedbackEnterDescriptionError;

  /// No description provided for @servantFeedbackAddAtLeastOneQuestionError.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one question to the feedback form.'**
  String get servantFeedbackAddAtLeastOneQuestionError;

  /// No description provided for @servantFeedbackValidDatesError.
  ///
  /// In en, this message translates to:
  /// **'Please select valid start and end dates.'**
  String get servantFeedbackValidDatesError;

  /// No description provided for @servantFeedbackEndAfterStartError.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date.'**
  String get servantFeedbackEndAfterStartError;

  /// No description provided for @servantFeedbackSelectTypeError.
  ///
  /// In en, this message translates to:
  /// **'Please select a type.'**
  String get servantFeedbackSelectTypeError;

  /// No description provided for @servantFeedbackCreateFormFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create feedback form. Please try again.'**
  String get servantFeedbackCreateFormFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
