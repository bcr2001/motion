// contains all the main app string
class AppString {
  // MOTION CORE
  // default quote
  static const String defaultAppQuote =
      "“Time is what we want most, but what we use worst.” - William Penn";
  // mc_firebase
  static const String firebaseUserNotFoundError = "User no found";
  static const String firebaseIncorrectPassword = "Incorrect password";
  static const String firebaseSomethingWentWrong =
      "Something went wrong on our side :(";
  static const String firebaseEmailInUse =
      "The email you provided is already in use";
  static const String firebaseUnableToSignOut = "Unable to sign out";
  static const String firebaseGoogleSignInError =
      "Check your internet connection and try again...";

  // edit page
  static const String editPageAppBarTitle = "Edit";
  static const String deleteTitle = "Delete";
  static const String editPageUpdateButtonName = "UPDATE";
  static const String editPageDescription =
      "Edit, archive, delete the subcategories and their corresponding main categories below:";
  static const String editPageUpdateError =
      "Please select a value from the drop-down.";

  // Navigation bar names
  static const String homeNavigation = "Home";
  static const String statsNavigation = "Stats";

  // App bar titles
  static const String statsRouteTitle = "Analytics Summary";
  static const String motionRouteTitle = "Track";
  static const String logOutTitle = "Log out";
  static const String cancelTitle = "Cancel";
  static const String settingsTitle = "Settings";
  static const String tipsTitle = "Tips";
  static const String themeSettingsTitle = "Theme Settings";

  static const String logOutQuestion = "Are you sure you want to log out?";

  // popup menu button values
  static const String logOutValue = "logout";
  static const String settingsValue = "setting";
  static const String tipsValue = "tips";

  // settings page
  static const String themeTitle = "Theme";
  static const String downloadDataTitle = "Download Personal Data";
  static const String notificationTitle = "Notification";
  static const String importDataTitle = "Import Data";
  static const String aboutMotionTitle = "About Motion";

  static const String downloadDataDescription =
      "Download all your personal data.";
  static const String notificationDescription =
      "Personalize your notification settings.";
  static const String importDataDescription = "Bring your data into Motion.";
  static const String aboutMotionDescription =
      "Discover the essence of Motion.";
  static const String themeSettingPageMessage = "Switch to your prefered theme";
  static const ligthMode = "Light Mode";
  static const darkMode = "Dark Mode";
  static const systemDefault = "System Default";

  // sign in/ sign out page
  static const String logInTitle = "Log In";
  static const String registerTitle = "Register";

  static const String emailHintText = "Email";
  static const String passwordHintText = "Password";
  static const String confirmPasswordHintText = "Confirm Password";

  static const String logInWelcomeMessage =
      "Welcome back to Motion! Log in to track your time, stay organized, and boost productivity !!";
  static const String signUpWelcomeMessage =
      "Join Motion and unlock the power of time management. Sign up today to start tracking your time efficiently and achieving your goals";

  static const String or = "Or";
  static const String continueWithGoogle = "Continue with Google";

  static const String emptyEmailValidatorMessage = "please enter your email";
  static const String invalidEmailValidatorMessage = "Enter a valid email";
  static const String invalidPasswordValidatorMessage =
      "password must be more than 6 characters long";
  static const String emptyPasswordValidatorMessage = "please enter a password";
  static const String emptyConfirmPasswordValidatorMessage =
      "please confirm password";
  static const String emptyUserNameValidatorMessage = "please enter a username";

  static const String areYouAMemeber = "Are you not a member?";
  static const String registerHere = " Register Here";
  static const String alreadyMember = "Already a memeber? ";
  static const String confirmNotEqual = "does not match password";

  static const String userPfpModalProfile = "Profile Picture";
  static const String userPfpModalGallery = "Gallery";

  // About page
  static const String motionTitle = "Motion";
  static const String currentMotionVersion = "Current App version 0.0.1.2";
  static const String appDescription =
      "Motion offers a user-friendly and effective solution for tracking and analyzing time, providing tools for seamless data collection, visual representation, and comprehensive reporting.";
  static const String motionLLC = "MOTION LLC. ALL RIGHTS RESERVED";

  // TRACK (MOTION) PAGE
  static const String educationMainCategory = "Education";
  static const String skillMainCategory = "Skills";
  static const String entertainmentMainCategory = "Entertainment";
  static const String selfDevelopmentMainCategory = "Self Development";
  static const String sleepMainCategory = "Sleep";

  static const String addItem = "Add";
  static const String unknown = "unknown";
  static const newAlertDialogTitle = "Create a new subcategory";

  static const String emptySubcategoryValidatorMessage = "empty subcategory";
  static const String subcategoryContainsNumberMessage =
      "a subcategory name cannot contain numbers";
  static const String subcategoryContainsSpacesMessage =
      "use '/' to separate grouped subcategories";
  static const String trackTextFormFieldHintText = "Subcategory Name";
  static const String trackCancelTextButton = "CANCEL";
  static const String trackAddTextButton = "ADD";
  static const String trackDropDownHintText = "Select a Main Category";
  static const String trackMainCategoryNotSelectedError =
      "Please select a value from the drop-down.";

  // MANUAL RECORDING ROUTE
  static const String manualAddBlock = "Add time block";
  static const String manualSave = "Save";
  static const String blockTitle = "Today’s Blocks";
  static const String timeCreated = "Time Created:";
  static const String manualInvalidValueError = "Please enter valid values";
  static const String manualRangeValueError = "Keep entries within range!!";

  // HOME ROUTE
  static const String homeSubcategoryTitle = "Subcategories";
  static const String trackingWindowTitle = "Tracking Window";
  static const String summaryTitle = "Summary";
  static const String accountedTitle = "Accounted";
  static const String unAccountedTitle = "Unaccounted";
  static const String monthlyTimeTrackingChartTitle =
      "Monthly Time Tracking Chart";
  static const String zenQuotesDefault =
      "“Time is what we want most, but what we use worst.” - William Penn";

  static const String subcategoryTitle = "Subcategory";
  static const String mainCategoryTitle = "Main Categories";

  static const String infoAboutSummaryWindow =
      "Information on time tracked within the tracking window will be summarized and showcased here. You can switch between Subcategory Summary and Main Category Summary. This summary pertains to the ongoing month.";

  static const String infoAboutSummaryWindow2 =
      "Subcategory and Main Category totals and averages for the current month.";

  // Report Page
  static const String reportTitle = "Report";
  static const String contributionTitle = "Contributions";
  static const String accountedVsUnaccounterTitle = "Accounted vs Unaccounted";
  static const String mostTrackedMainTitle = "Most Tracked\nMain Category";
  static const String leastTrackedMainTitle = "Least Tracked\nMain Category";
  static const String mostTrackedTitle = "Most Tracked";
  static const String leastTrackedTitle = "Least Tracked";
  static const String mostAndLeastTrackedTitle = "Most and Least Tracked";
  static const String mainCategoryDistributionTitle =
      "Main Category Distribution";
  static const String highestTrackedTimeTitleMain = "Highest Tracked Time";
  static const String highestTrackedTimeTitleSpecial = "Per Subcategory";

  static const String informationAboutSleep =
      "The amount of time you spend sleeping is not considered when determining the most and least time tracked.";
  static const String informationAboutHighestTrackedTime =
      "During the month, these are the highest durations you have spent on specific subcategories, along with the dates they were recorded.";
  static const String informationAboutContribution =
      "Entertainment subcategories do not affect your contribution score.";
  static const String informationAboutNoData = "No data";

  static const String subcategory1 = "Subcategory 1";
  static const String subcategory2 = "Subcategory 2";
  static const String subcategory3 = "Subcategory 3";

  static const String hoursTimeSpentHolder = "0.00";
  static const String firstDayOfTrackingEver = "01/07/2021";

  // STATS ROUTE
  static const String totalAccountedTitle = "Total Accounted";
  static const String totalUnaccountedTitle = "Total Unaccounted";
  static const String mainCategoryOverview = "Main Category Overview";
  static const String aYearInSlicesTitle = "A Year in Slices";
  static const String distributionTitle = "Distribution";
  static const String distributionTitle2 = "Lines of";
  static const String statusTitle = "Status";
  static const String statusUpTitle = "Up";
  static const String mainCategorySummaryTitle = "Category Summary Report";
  static const String yearlyReportTitle = "Annual Overview";

  static const String chartingAYearInLinesTitle = "Graphing a Year in Lines";
  static const String stackingAYearInLinesTitle = "Stacking Up Your Year";
  static const String stackingATitle = "Stacking";
  static const String entireLifeTitle = "Entire Life";
  static const String entireLifeInSlicesTitle = "in slices";

  static const String infoAboutAnnualOverviewEmpty =
      "Initiate the tracking process to generate and display your comprehensive yearly summary here..";
  static const String infoAboutMonthlyReportEmpty =
      "Initiate the tracking process to generate and display your comprehensive monthly report here..";
  static const String infoAboutGalleys =
      "To access the summary and analysis for a specific year, click on that year.";
  static const String infoAboutHighestTimeTracked =
      "Below are the highest recorded durations for each subcategory, along with the respective dates during which they were logged over the course of the year.";
  static const String infoAboutGroupedBarChart =
      "The accounted and unaccounted time for a given month is delineated in days. ";
  static const String infoAboutLineChartData =
      "The Main Category data values for a given month are delineated in hours. ";
  static const String infoAboutStackChartData =
      "A monthly Distribution of Main Categories";

  // TIPS ROUTE

  static const String tipsImportantNoteTitle = "Important Notes";
  static const String note1TrackingGuide =
      "To accurately monitor your activities, start a stopwatch on your phone or device when you begin a task. Stop it once you finish, then log the time in the app's relevant subcategory. This method ensures precise tracking of time spent on each activity.";
  static const String note2NoEstimating =
      "If you forget to start the timer when beginning an activity, don't guess the elapsed time. Instead, consider that period as untracked and start timing from the moment you remember, treating it as the activity's start.";
  static const String note3IndividualUseOnly =
      "This tracking system is intended for individual use and should only be used for specific, focused activities. Please avoid tracking activities that do not have a clear and defined purpose.";
  static const String note4ConciseTracking =
      "To avoid confusion and keep your tracking list clear, it's best to use broader subcategories. For example, instead of tracking each school subject separately, group them under a more general category like 'Studying.'";
  static const String note5subcategoryAssignment =
      "When assigning subcategories to main categories, carefully consider their placement since the categorization can be nuanced. Refer to the FOUNDERS gallery for ideas on effective organization. Remember, categorization can be subjective, so adjust as needed to fit your application's specific objectives and user preferences.";
  static const String note6KeyExamples =
      "Below are the main categories and key EXAMPLES of subcategories that can be tracked under each one. Tracking the main categories directly is not feasible, so corresponding subcategories must be created for each main category.";
  static const String note7BackSlashAlert =
      "Please note that the '/'symbol is used to indicate alternative names for subcategories, and you have the flexibility to name subcategories in the way that best suits your preferences.";
}
