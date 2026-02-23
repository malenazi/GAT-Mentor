import 'package:flutter/material.dart';

/// Lightweight localization class — no code-gen required.
///
/// Usage:  `S.of(context).welcomeBack`
class S {
  static S of(BuildContext context) {
    return S._(Localizations.localeOf(context).languageCode == 'ar');
  }

  final bool isAr;
  S._(this.isAr);

  String _t(String en, String ar) => isAr ? ar : en;
  TextDirection get direction => isAr ? TextDirection.rtl : TextDirection.ltr;

  // ===========================================================================
  // General / Shared
  // ===========================================================================
  String get appTitle => _t('GAT Mentor', 'مرشد القدرات');
  String get retry => _t('Retry', 'إعادة المحاولة');
  String get cancel => _t('Cancel', 'إلغاء');
  String get submit => _t('Submit', 'إرسال');
  String get save => _t('Save', 'حفظ');
  String get next => _t('Next', 'التالي');
  String get back => _t('Back', 'رجوع');
  String get continueText => _t('Continue', 'متابعة');
  String get leave => _t('Leave', 'مغادرة');
  String get stay => _t('Stay', 'البقاء');
  String get home => _t('Home', 'الرئيسية');
  String get goHome => _t('Go Home', 'الرئيسية');
  String get goBack => _t('Go Back', 'رجوع');
  String get accuracy => _t('Accuracy', 'الدقة');
  String get questions => _t('Questions', 'الأسئلة');
  String get days => _t('days', 'أيام');
  String get loading => _t('Loading...', 'جاري التحميل...');

  // ===========================================================================
  // Auth – Login
  // ===========================================================================
  String get welcomeBack => _t('Welcome Back', 'مرحباً بعودتك');
  String get signInSubtitle =>
      _t('Sign in to continue your GAT preparation',
         'سجل دخولك لمتابعة تحضيرك لاختبار القدرات');
  String get email => _t('Email', 'البريد الإلكتروني');
  String get emailHint => _t('you@example.com', 'you@example.com');
  String get pleaseEnterEmail =>
      _t('Please enter your email', 'يرجى إدخال بريدك الإلكتروني');
  String get pleaseEnterValidEmail =>
      _t('Please enter a valid email', 'يرجى إدخال بريد إلكتروني صحيح');
  String get password => _t('Password', 'كلمة المرور');
  String get enterPassword =>
      _t('Enter your password', 'أدخل كلمة المرور');
  String get pleaseEnterPassword =>
      _t('Please enter your password', 'يرجى إدخال كلمة المرور');
  String get passwordMinLength =>
      _t('Password must be at least 6 characters',
         'يجب أن تكون كلمة المرور 6 أحرف على الأقل');
  String get signIn => _t('Sign In', 'تسجيل الدخول');
  String get noAccount => _t("Don't have an account? ", 'ليس لديك حساب؟ ');
  String get register => _t('Register', 'تسجيل');

  // ===========================================================================
  // Auth – Register
  // ===========================================================================
  String get createAccount => _t('Create Account', 'إنشاء حساب');
  String get registerSubtitle =>
      _t('Start your personalized GAT prep journey',
         'ابدأ رحلتك الشخصية للتحضير لاختبار القدرات');
  String get fullName => _t('Full Name', 'الاسم الكامل');
  String get fullNameHint => _t('Ahmed Khan', 'أحمد خان');
  String get pleaseEnterName =>
      _t('Please enter your full name', 'يرجى إدخال اسمك الكامل');
  String get nameMinLength =>
      _t('Name must be at least 2 characters',
         'يجب أن يكون الاسم حرفين على الأقل');
  String get passwordHint =>
      _t('At least 6 characters', '6 أحرف على الأقل');
  String get pleaseEnterAPassword =>
      _t('Please enter a password', 'يرجى إدخال كلمة مرور');
  String get alreadyHaveAccount =>
      _t('Already have an account? ', 'لديك حساب بالفعل؟ ');
  String get login => _t('Login', 'تسجيل الدخول');

  // Password strength
  String get tooShort => _t('Too short', 'قصيرة جداً');
  String get weak => _t('Weak', 'ضعيفة');
  String get fair => _t('Fair', 'مقبولة');
  String get good => _t('Good', 'جيدة');
  String get strong => _t('Strong', 'قوية');
  String get passwordRequirements =>
      _t('Use 8+ characters with uppercase, lowercase, numbers & symbols',
         'استخدم 8 أحرف أو أكثر مع أحرف كبيرة وصغيرة وأرقام ورموز');

  // ===========================================================================
  // Navigation
  // ===========================================================================
  String get practice => _t('Practice', 'تدريب');
  String get dashboard => _t('Dashboard', 'لوحة المتابعة');
  String get profile => _t('Profile', 'الملف الشخصي');
  String get review => _t('Review', 'مراجعة');

  // Admin nav
  String get adminDashboard => _t('Dashboard', 'لوحة التحكم');
  String get adminQuestions => _t('Questions', 'الأسئلة');

  // ===========================================================================
  // Profile Setup / Onboarding
  // ===========================================================================
  String get setupProfile => _t('Set Up Your Profile', 'إعداد ملفك الشخصي');
  String get whatFocus =>
      _t('What would you like\nto focus on?', 'على ماذا تريد\nأن تركز؟');
  String get chooseFocusArea =>
      _t('Choose the area you want to improve',
         'اختر المجال الذي تريد تحسينه');
  String get quantitative => _t('Quantitative', 'كمي');
  String get quantDesc =>
      _t('Numbers, algebra, geometry & data', 'أرقام، جبر، هندسة وبيانات');
  String get verbal => _t('Verbal', 'لفظي');
  String get verbalDesc =>
      _t('Reading, vocabulary & reasoning', 'قراءة، مفردات واستدلال');
  String get both => _t('Both', 'كلاهما');
  String get bothDesc =>
      _t('Complete GAT preparation', 'تحضير شامل لاختبار القدرات');
  String get describeLevel =>
      _t('How would you describe\nyour current level?',
         'كيف تصف\nمستواك الحالي؟');
  String get personalizeStart =>
      _t('This helps us personalize your starting point',
         'يساعدنا هذا في تخصيص نقطة البداية');
  String get beginner => _t('Beginner', 'مبتدئ');
  String get beginnerDesc =>
      _t('Just starting out or need a refresher',
         'بدأت للتو أو تحتاج لمراجعة');
  String get average => _t('Average', 'متوسط');
  String get averageDesc =>
      _t('Comfortable but want to improve', 'مرتاح لكن تريد التحسن');
  String get highScorer => _t('High Scorer', 'متفوق');
  String get highScorerDesc =>
      _t('Strong foundation, aiming for top marks',
         'أساس قوي، تسعى لأعلى الدرجات');
  String get whenExam =>
      _t('When is your\nGAT exam?', 'متى موعد\nاختبار القدرات؟');
  String get studyPlanDeadline =>
      _t("We'll create a study plan around your deadline",
         'سننشئ خطة دراسية حول موعدك');
  String get tapSelectDate =>
      _t('Tap to select a date', 'اضغط لاختيار التاريخ');
  String get noDateYet =>
      _t("I don't have a date yet", 'ليس لدي موعد بعد');
  String get setStudyGoals =>
      _t('Set your study goals', 'حدد أهدافك الدراسية');
  String get changeInSettings =>
      _t('You can always change these later in settings',
         'يمكنك تغيير هذه الإعدادات لاحقاً');
  String get dailyStudyTime =>
      _t('Daily Study Time', 'وقت الدراسة اليومي');
  String get targetScore => _t('Target Score', 'الدرجة المستهدفة');
  String get startDiagnostic =>
      _t('Start Diagnostic', 'بدء الاختبار التشخيصي');

  // ===========================================================================
  // Diagnostic
  // ===========================================================================
  String get loadingDiagnostic =>
      _t('Loading diagnostic questions...',
         'جاري تحميل أسئلة الاختبار التشخيصي...');
  String get preparingQuestions =>
      _t('Preparing questions...', 'جاري تحضير الأسئلة...');
  String get diagnosticAssessment =>
      _t('Diagnostic Assessment', 'الاختبار التشخيصي');
  String get leaveDiagnostic =>
      _t('Leave Diagnostic?', 'مغادرة الاختبار التشخيصي؟');
  String get diagnosticLeaveWarning =>
      _t('Your progress will be lost. Are you sure you want to leave?',
         'سيتم فقدان تقدمك. هل أنت متأكد من المغادرة؟');
  String get submissionFailed =>
      _t('Submission failed', 'فشل الإرسال');

  // Diagnostic Result
  String get analyzingResults =>
      _t('Analyzing your results...', 'جاري تحليل نتائجك...');
  String get diagnosticComplete =>
      _t('Diagnostic Complete!', 'اكتمل الاختبار التشخيصي!');
  String get recommendedLevel =>
      _t('Recommended Level', 'المستوى الموصى به');
  String get performanceByConcept =>
      _t('Performance by Concept', 'الأداء حسب المفهوم');
  String get startLearning =>
      _t('Start Learning', 'ابدأ التعلم');
  String get highScorerFeedback =>
      _t('Excellent performance! You have a strong foundation. Let\'s push for mastery.',
         'أداء ممتاز! لديك أساس قوي. دعنا نسعى للإتقان.');
  String get averageFeedback =>
      _t('Good start! We\'ve identified areas to focus on. Your personalized plan is ready.',
         'بداية جيدة! حددنا مجالات للتركيز عليها. خطتك الشخصية جاهزة.');
  String get beginnerFeedback =>
      _t('Great job completing the diagnostic! We\'ll build your skills step by step with a tailored study plan.',
         'أحسنت في إكمال الاختبار! سنبني مهاراتك خطوة بخطوة مع خطة دراسية مخصصة.');

  // ===========================================================================
  // Home
  // ===========================================================================
  String get loadingPlan =>
      _t('Loading your plan...', 'جاري تحميل خطتك...');
  String get goodMorning => _t('Good morning', 'صباح الخير');
  String get goodAfternoon => _t('Good afternoon', 'مساء الخير');
  String get goodEvening => _t('Good evening', 'مساء الخير');
  String get student => _t('Student', 'طالب');
  String get todaysPlan => _t("Today's Plan", 'خطة اليوم');
  String get done => _t('done', 'مكتمل');
  String get todaysProgress =>
      _t("Today's Progress", 'تقدم اليوم');
  String get tasksCompleted =>
      _t('tasks completed', 'مهام مكتملة');
  String get noPlanToday =>
      _t('No plan for today', 'لا توجد خطة لهذا اليوم');
  String get startPracticingPrompt =>
      _t('Start practicing to generate your\npersonalized study plan.',
         'ابدأ التدريب لإنشاء\nخطتك الدراسية الشخصية.');
  String get quickActions =>
      _t('Quick Actions', 'إجراءات سريعة');
  String get timedSet => _t('Timed Set', 'اختبار موقّت');
  String get warmUp => _t('Warm-up', 'تحمية');
  String get weakTopic => _t('Weak Topic', 'موضوع ضعيف');
  String get timedSprint => _t('Timed Sprint', 'سباق موقّت');

  // ===========================================================================
  // Practice
  // ===========================================================================
  String get findingQuestion =>
      _t('Finding your next question...',
         'جاري البحث عن سؤالك التالي...');
  String get tryAgain => _t('Try Again', 'حاول مرة أخرى');
  String get readyToPractice =>
      _t('Ready to practice!', 'جاهز للتدريب!');
  String get tapToStart =>
      _t('Tap the button below to get your first question.',
         'اضغط الزر أدناه للحصول على سؤالك الأول.');
  String get startPractice =>
      _t('Start Practice', 'بدء التدريب');
  String get veryEasy => _t('Very Easy', 'سهل جداً');
  String get easy => _t('Easy', 'سهل');
  String get medium => _t('Medium', 'متوسط');
  String get hard => _t('Hard', 'صعب');
  String get veryHard => _t('Very Hard', 'صعب جداً');
  String get hint => _t('Hint', 'تلميح');
  String get correct => _t('Correct!', 'صحيح!');
  String get notQuiteRight =>
      _t('Not quite right', 'ليست الإجابة الصحيحة');
  String get greatJobAnswer =>
      _t('Great job! The answer is ', 'أحسنت! الإجابة هي ');
  String get correctAnswerIs =>
      _t('The correct answer is ', 'الإجابة الصحيحة هي ');
  String get mastery => _t('Mastery: ', 'الإتقان: ');
  String get why => _t('Why ', 'لماذا ');
  String get isWrong => _t(' is wrong', ' خاطئة');
  String get viewSolution =>
      _t('View Solution', 'عرض الحل');
  String get nextQuestion =>
      _t('Next Question', 'السؤال التالي');
  String get submitAnswer =>
      _t('Submit Answer', 'إرسال الإجابة');
  String get guess => _t('Guess', 'تخمين');

  // ===========================================================================
  // Solution
  // ===========================================================================
  String get solution => _t('Solution', 'الحل');
  String get question => _t('Question', 'السؤال');
  String get answer => _t('Answer', 'الإجابة');
  String get stepByStepSolution =>
      _t('Step-by-Step Solution', 'الحل خطوة بخطوة');
  String get backToPractice =>
      _t('Back to Practice', 'العودة للتدريب');

  // ===========================================================================
  // Review Queue
  // ===========================================================================
  String get reviewQueue => _t('Review Queue', 'قائمة المراجعة');
  String get refresh => _t('Refresh', 'تحديث');
  String get noReviewsDue =>
      _t('No reviews due!', 'لا توجد مراجعات مستحقة!');
  String get keepPracticingReview =>
      _t('Keep practicing and any mistakes\nwill show up here for review.',
         'واصل التدريب وأي أخطاء\nستظهر هنا للمراجعة.');
  String get yourAnswer => _t('Your Answer', 'إجابتك');
  String get correctLabel => _t('Correct', 'صحيح');
  String get explanation => _t('Explanation', 'الشرح');
  String get stillConfused =>
      _t('Still Confused', 'لا زلت مرتبكاً');
  String get gotIt => _t('Got It!', 'فهمت!');
  String get reviewed => _t('Reviewed ', 'تمت مراجعة ');

  // ===========================================================================
  // Dashboard
  // ===========================================================================
  String get yourDashboard =>
      _t('Your Dashboard', 'لوحة المتابعة');
  String get startFirstPractice =>
      _t('Start your first practice session!',
         'ابدأ أول جلسة تدريب!');
  String get amazingWork =>
      _t('Amazing work! Keep pushing for mastery!',
         'عمل رائع! واصل السعي للإتقان!');
  String get greatProgress =>
      _t('Great progress! You\'re getting stronger!',
         'تقدم رائع! أنت تتحسن!');
  String get dontBreakStreak =>
      _t(' day streak! Don\'t break it!',
         ' أيام متتالية! لا تقطع السلسلة!');
  String get everyQuestionMatters =>
      _t('Every question makes you better. Keep going!',
         'كل سؤال يجعلك أفضل. واصل!');
  String get avgTime => _t('Avg Time', 'متوسط الوقت');
  String get streak => _t('Streak', 'السلسلة');
  String get studyTime => _t('Study Time', 'وقت الدراسة');
  String get bestStreak => _t('Best Streak', 'أفضل سلسلة');
  String get topicPerformance =>
      _t('Topic Performance', 'الأداء حسب الموضوع');
  String get topicPerformanceDesc =>
      _t('How you\'re doing across each GAT section',
         'أداؤك في كل قسم من أقسام القدرات');
  String get mastered => _t('Mastered', 'متقن');
  String get concepts => _t('Concepts', 'المفاهيم');
  String get whatToFocus =>
      _t('What to Focus On', 'ما يجب التركيز عليه');
  String get focusDesc =>
      _t('Concepts that need your attention most',
         'المفاهيم التي تحتاج أكبر اهتمامك');
  String get onFire => _t("You're on fire!", 'أنت متألق!');
  String get allConceptsGreat =>
      _t('All concepts are at a great level. Keep practicing to maintain mastery!',
         'جميع المفاهيم في مستوى رائع. واصل التدريب للحفاظ على الإتقان!');
  String get masteryMap =>
      _t('Mastery Map', 'خريطة الإتقان');
  String get masteryMapDesc =>
      _t('Detailed concept-level breakdown',
         'تفصيل مفصل على مستوى المفاهيم');
  String get accuracyTrend =>
      _t('Accuracy Trend', 'اتجاه الدقة');
  String get accuracyTrendDesc =>
      _t('Your accuracy over the last 7 days',
         'دقتك خلال الأيام السبعة الأخيرة');
  String get practiceWeakTopics =>
      _t('Practice Weak Topics', 'تدريب على المواضيع الضعيفة');

  // ===========================================================================
  // Exam Simulation
  // ===========================================================================
  String get examSimulation =>
      _t('Exam Simulation', 'محاكاة الاختبار');
  String get simulateRealExam =>
      _t('Simulate a Real Exam', 'محاكاة اختبار حقيقي');
  String get simulationDesc =>
      _t('No hints, no immediate feedback.\nTest yourself under exam conditions.',
         'بدون تلميحات أو تغذية راجعة فورية.\nاختبر نفسك في ظروف الاختبار.');
  String get numberOfQuestions =>
      _t('Number of Questions', 'عدد الأسئلة');
  String get filterByTopic =>
      _t('Filter by Topic (Optional)', 'تصفية حسب الموضوع (اختياري)');
  String get allTopics => _t('All Topics', 'جميع المواضيع');
  String get difficultyPreference =>
      _t('Difficulty Preference (Optional)',
         'تفضيل الصعوبة (اختياري)');
  String get mixed => _t('Mixed', 'مختلط');
  String get startSimulation =>
      _t('Start Simulation', 'بدء المحاكاة');
  String get starting => _t('Starting...', 'جاري البدء...');
  String get simulation => _t('Simulation', 'المحاكاة');
  String get noQuestionsAvailable =>
      _t('No questions available.', 'لا توجد أسئلة متاحة.');
  String questionOf(int current, int total) =>
      _t('Question $current of $total', 'السؤال $current من $total');
  String get submitExam => _t('Submit Exam?', 'إرسال الاختبار؟');
  String unansweredWarning(int count) =>
      _t('You have $count unanswered question${count == 1 ? '' : 's'}',
         'لديك $count ${count == 1 ? 'سؤال' : 'أسئلة'} بدون إجابة');
  String get sureSubmit =>
      _t('Are you sure you want to submit?',
         'هل أنت متأكد من الإرسال؟');
  String get sureSubmitExam =>
      _t('Are you sure you want to submit your exam?',
         'هل أنت متأكد من إرسال الاختبار؟');
  String get prev => _t('Prev', 'السابق');
  String get submitAll => _t('Submit All', 'إرسال الكل');
  String get submitting => _t('Submitting...', 'جاري الإرسال...');
  String get leaveSimulation =>
      _t('Leave Simulation?', 'مغادرة المحاكاة؟');
  String get simulationLeaveWarning =>
      _t('Your progress will be lost if you leave now.',
         'سيتم فقدان تقدمك إذا غادرت الآن.');
  String youWillHave(int minutes, int questions) =>
      _t('You will have $minutes minutes to complete $questions questions.',
         'لديك $minutes دقيقة لإكمال $questions سؤال.');

  // Simulation Result
  String get greatJob => _t('Great Job!', 'أحسنت!');
  String get keepPracticing =>
      _t('Keep Practicing!', 'واصل التدريب!');
  String get didWellSimulation =>
      _t('You did well on this simulation!',
         'أداؤك كان جيداً في هذه المحاكاة!');
  String get everyAttemptStronger =>
      _t('Every attempt makes you stronger.',
         'كل محاولة تجعلك أقوى.');
  String get timeTaken => _t('Time Taken', 'الوقت المستغرق');
  String get perTopicBreakdown =>
      _t('Per-Topic Breakdown', 'التفصيل حسب الموضوع');
  String get reviewMistakes =>
      _t('Review Mistakes', 'مراجعة الأخطاء');

  // ===========================================================================
  // Profile
  // ===========================================================================
  String get studySettings =>
      _t('Study Settings', 'إعدادات الدراسة');
  String get editAll => _t('Edit All', 'تعديل الكل');
  String get studyPlan => _t('Study Plan', 'خطة الدراسة');
  String get examDate => _t('Exam Date', 'تاريخ الاختبار');
  String get notSet => _t('Not set', 'غير محدد');
  String get dailyMinutes =>
      _t('Daily Minutes', 'الدقائق اليومية');
  String get currentStreak =>
      _t('Current Streak', 'السلسلة الحالية');
  String get level => _t('Level', 'المستوى');
  String get daysActive => _t('Days Active', 'أيام النشاط');
  String get logout => _t('Logout', 'تسجيل الخروج');
  String get logoutConfirm =>
      _t('Are you sure you want to log out?',
         'هل أنت متأكد من تسجيل الخروج؟');
  String day(int count) =>
      _t('$count day${count == 1 ? '' : 's'}',
         '$count ${count == 1 ? 'يوم' : 'أيام'}');
  String minutes(int count) =>
      _t('$count minutes', '$count دقيقة');

  // Plan Settings
  String get studyPlanSettings =>
      _t('Study Plan Settings', 'إعدادات خطة الدراسة');
  String get whenGatExam =>
      _t('When is your GAT exam?', 'متى اختبار القدرات؟');
  String get selectExamDate =>
      _t('Select exam date', 'اختر تاريخ الاختبار');
  String get howManyMinutes =>
      _t('How many minutes do you want to study each day?',
         'كم دقيقة تريد أن تدرس يومياً؟');
  String get whatScoreAiming =>
      _t('What score are you aiming for?',
         'ما الدرجة التي تسعى إليها؟');
  String get currentLevel =>
      _t('Current Level', 'المستوى الحالي');
  String get howDescribeAbility =>
      _t('How would you describe your current ability?',
         'كيف تصف مستواك الحالي؟');
  String get saveSettings =>
      _t('Save Settings', 'حفظ الإعدادات');
  String get saving => _t('Saving...', 'جاري الحفظ...');
  String daysUntilExam(int count) =>
      _t('$count days until your exam',
         '$count يوم على اختبارك');
  String get examDatePassed =>
      _t('Exam date has passed', 'تاريخ الاختبار قد مضى');

  // ===========================================================================
  // Admin
  // ===========================================================================
  String get adminDashboardTitle =>
      _t('Admin Dashboard', 'لوحة تحكم المشرف');
  String get platformOverview =>
      _t('Platform overview', 'نظرة عامة على المنصة');
  String get admin => _t('Admin', 'مشرف');
  String get totalUsers => _t('Total Users', 'إجمالي المستخدمين');
  String get activeQuestions =>
      _t('Active Questions', 'الأسئلة النشطة');
  String get totalAttempts =>
      _t('Total Attempts', 'إجمالي المحاولات');
  String get avgMastery => _t('Avg Mastery', 'متوسط الإتقان');
  String get adminActions =>
      _t('Admin Actions', 'إجراءات المشرف');
  String get manageQuestions =>
      _t('Manage Questions', 'إدارة الأسئلة');
  String get manageQuestionsDesc =>
      _t('View, edit, or deactivate questions',
         'عرض أو تعديل أو تعطيل الأسئلة');
  String get bulkUpload =>
      _t('Bulk Upload', 'رفع جماعي');
  String get bulkUploadDesc =>
      _t('Upload questions via API', 'رفع الأسئلة عبر الواجهة البرمجية');
  String get loadingAdminStats =>
      _t('Loading admin stats...', 'جاري تحميل إحصائيات المشرف...');
  String get questionManagement =>
      _t('Question Management', 'إدارة الأسئلة');
  String get loadingQuestions =>
      _t('Loading questions...', 'جاري تحميل الأسئلة...');
  String get noQuestionsFound =>
      _t('No questions found', 'لا توجد أسئلة');
  String get deactivate => _t('Deactivate', 'تعطيل');
  String get deactivateQuestion =>
      _t('Deactivate Question?', 'تعطيل السؤال؟');
  String get deactivateWarning =>
      _t('This question will no longer appear in practice sessions.',
         'لن يظهر هذا السؤال في جلسات التدريب بعد الآن.');
  String get previous => _t('Previous', 'السابق');

  // ===========================================================================
  // Language
  // ===========================================================================
  String get language => _t('Language', 'اللغة');
  String get english => _t('English', 'English');
  String get arabic => _t('العربية', 'العربية');
  String get switchLanguage =>
      _t('العربية', 'English');

  // ===========================================================================
  // Session
  // ===========================================================================
  String get sessionExpired =>
      _t('Session Expired', 'انتهت الجلسة');
  String get sessionExpiredMsg =>
      _t('Your session has expired. Please log in again.',
         'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.');
  String get focus => _t('Focus', 'التركيز');
}
