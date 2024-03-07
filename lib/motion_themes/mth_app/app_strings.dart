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
      "Edit, archive, and delete subcategories below:";
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
  static const String tipsTitle = "FAQ";
  static const String themeSettingsTitle = "Theme Settings";
  static const String subcategoryExampleTitles = "Subcategory Examples";

  static const String logOutQuestion = "Are you sure you want to log out?";

  // popup menu button values
  static const String logOutValue = "logout";
  static const String settingsValue = "setting";
  static const String tipsValue = "faq";

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
  static const String efficiencyScoreTitle = "EFS";
  static const String entireTitle = "Entire";
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

  static const String mostProductiveDay = "Most Productive Day";
  static const String leastProductiveDay = "Least Productive Day";

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

  // FAQ ROUTE
  // notes

  // (questions)
  static const String faq1SubcategoryExamplesQ =
      "1. What are some examples of subcategories I can keep track of?";
  static const String faq2AccuracyMoneteringQ =
      "2. How can I accurately monitor my activities and track time spent on each task?";
  static const String faq3ForgetTimerQ =
      "3. What should I do if I forget to start the timer when initiating an activity?";
  static const String faq4AnyActivityQ =
      "4. What type of activities should I track with this system?";
  static const String faq5GeneralOrSpecificQ =
      "5. Should I keep my subcategories specific or general when tracking activities?";
  static const String faq6AssignToMainQ =
      "6. How should I assign subcategories to their respective main categories?";
  static const String faq7EFSQ =
      "7. What does EFS stand for, and how is it used?";


  // (answers)
  static const String faq2AccuracyMoneteringAnswer =
      "To accurately monitor your activities, start a stopwatch on your phone or device when you begin a task. Stop it once you finish, then log the time in the app's relevant subcategory. This method ensures precise tracking of time spent on each activity.";
  static const String faq3ForgetTimerAnswer =
      "If you initiate an activity and realize that you forgot to start the timer, do not estimate the time spent on the activity before remembering to initiate the timer. Instead, treat that initial period as untracked time and commence timing the activity as if it were the first instance of engagement.";
  static const String faq4AnyActivityAnswer =
      "This tracking system is designed for individual use, so it's important to track only specific, focused activities. Please refrain from tracking activities that lack a clear and focused purpose.";
  static const String faq5GeneralOrSpecificAnswer =
      "To prevent confusion and maintain a concise tracking list, it's advisable to keep the subcategories reasonably general. For instance, rather than tracking individual school subjects separately, you can encapsulate all the time spent under a broader category like 'Studied'";
  static const String faq6AssignToMainAnswer =
      "It's important to carefully consider the assignment of subcategories to their respective main categories, as there can be a fine line between which main category certain subcategories belong to. We recommend reviewing the FOUNDERS gallery for inspiration and guidance on how to organize these categories effectively. However, keep in mind that the organization can be somewhat subjective, so feel free to make adjustments as needed based on your application's unique goals and user preferences.";
  static const String faq7EFSAnswer =
      "EFS stands for Efficiency Score. It is a metric used to show how productive you are. The efficiency score is calculated for the current month, a specific year, and the overall efficiency score.";

  static const String note7BackSlashAlert =
      "Please note that the '/'symbol is used to indicate alternative names for subcategories, and you have the flexibility to name subcategories in the way that best suits your preferences.";

  // subcategory names
  static const String lectureClassSB1 = "Lectures/Class: ";
  static const String examsSB2 = "Exams: ";
  static const String assignmentHomeworkSB3 = "Assignment/Homework: ";
  static const String studiesRevisionSB4 = "Studies/Revision: ";
  static const String programmingCodingSB5 = "Programming/Coding: ";
  static const String graphicsDesignSB6 = "Graphics Design: ";
  static const String languagesSB7 =
      "Languages (e.g., Spanish/German/English): ";
  static const String musicSB8 = "Piano/Guitar/Violin Practice: ";
  static const String videoGamesSB9 = "Video Games: ";
  static const String moviesAndShowsSB10 = "Movies and TV Shows: ";
  static const String socialMediaSB11 = "Social Media: ";
  static const String journalingSB12 = "Journaling: ";
  static const String meditationSB13 = "Meditation: ";
  static const String exerciseSB14 = "Exercise/Workout: ";
  static const String sportsSB15 = "Football/Basketball/Any Other Sport: ";
  static const String sleepSB16 = "Sleep: ";
  static const String napSB17 = "Nap/Napping: ";

  // subcategory descriptions
  static const String lectureClassDB1 =
      "Time spent attending educational lectures or classes, specifically when a teacher or lecturer is actively teaching or has assigned a class activity. Do not track this time when in class with no active educational engagement.";
  static const String examsDB2 =
      "Time dedicated to taking exams, including the period starting from when you begin an exam to the moment you have completed it.";
  static const String assignmentHomeworkDB3 =
      "Time allocated for completing assignments or homework, specifically for assignments given out in class, regardless of whether knowledge of the assignment is known. Ensure not to mistakenly track this time under 'Studies' if the material was previously unknown.";
  static const String studiesRevisionDB4 =
      " Time devoted to independent study or focused learning activities outside of lectures and assignments.";
  static const String programmingCodingDB5 =
      "Time spent on coding, software development, or scripting tasks to enhance programming skills or work on personal projects.";
  static const String graphicsDesignDB6 =
      "Time invested in creative design activities, encompassing tasks such as creating visual content, developing design concepts, and refining artistic skills.";
  static const String languagesDB7 =
      "Time dedicated to language learning, encompassing activities such as studying vocabulary, practicing pronunciation, and engaging in language immersion.";
  static const String musicDB8 =
      "Time devoted to honing your skills on the respective musical instrument, involving exercises, scales, song practice, and technique refinement.";
  static const String videoGamesDB9 =
      "Time devoted to interactive gaming experiences, including playing video games on various platforms, exploring virtual worlds, completing quests, and honing gaming skills.";
  static const String moviesAndShowsDB10 =
      "Time allocated to viewing cinematic content, including movies, television series, and anime, for entertainment, information, or relaxation purposes.";
  static const String socialMediaDB11 =
      "Time allocated to engaging with social networking platforms, including browsing, posting, interacting with others, and staying updated with online connections and content. Note that primary chat applications like WhatsApp should not be tracked under this category.";
  static const String journalingDB12 =
      "Time devoted to the practice of maintaining a personal journal or diary, which may include writing about thoughts, emotions, experiences, and reflections on a regular basis.";
  static const String meditationDB13 =
      "Time dedicated to the practice of mindfulness and meditation techniques, involving focused breathing, relaxation, and mental clarity to promote inner peace, self-awareness, and stress reduction.";
  static const String exerciseDB14 =
      "Time devoted to physical activities aimed at improving fitness, strength, endurance, or overall health. This may include activities such as cardio workouts, strength training, flexibility exercises, and other fitness routines.";
  static const String sportsDB15 =
      "Time allocated to active participation in a specific sport, including training, matches, and drills. Track time when actively engaged in the sport, excluding breaks and non-sport-related activities. Please note that this category is distinct from general exercise or workouts.";
  static const String sleepDB16 =
      "Designed to track the duration of your sleep, allowing you to monitor how long you rest each night. This helps in understanding your sleep habits and ensuring you are getting enough sleep for your well-being.";
  static const String nappingDB17 =
      "Designed for recording brief periods of sleep, typically taken during the day. It's useful for tracking shorter rest periods that supplement your main sleep cycle, helping you understand their frequency and duration in your daily routine.";

  // main category information
  static const String entertainmentInfo =
      "This category excludes the tracking of reading fiction and non-fiction books, as well as activities involving board games, puzzles, or other games requiring participation from others. The application is designed for individual evaluation and primarily focuses on tracking time spent on personal entertainment and leisure activities, such as watching movies, TV shows, and anime.";
  static const String selfDevelopmentInfo =
      "All sporting and exercise activities are recommended to be tracked under this category. When tracking a specific sporting activity such as football, basketball, or any other, please start the timer when the game is actively being played. Do not track breaks or small talk outside the actual activity. It's important to note that a workout and a sporting activity are two different things, and they should be tracked separately.";
  static const String sleepInfo =
      "It's suggested to track both 'Sleep' and 'Nap/Napping' under the same main category. Alternatively, you could simply create a 'Sleep' subcategory and log all sleep-related activities there.";
}
