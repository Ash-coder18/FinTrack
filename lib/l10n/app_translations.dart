/// Lightweight localization for FinTrack.
///
/// Usage:
///   final t = AppTranslations.of(settings.languageLabel);
///   Text(t['settings']!)
class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    'English': _en,
    'Tamil': _ta,
  };

  /// Returns the translation map for the given language label.
  /// Falls back to English if the language is not found.
  static Map<String, String> of(String language) {
    return _translations[language] ?? _en;
  }

  // ── English ──────────────────────────────────────────────────
  static const Map<String, String> _en = {
    // ─── Settings Screen ───────────────────────────────────────
    // AppBar
    'settings': 'Settings',

    // Section Headers
    'appearance': 'Appearance',
    'currency': 'Currency',
    'reset_options': 'Reset Options',
    'about': 'About',

    // Appearance
    'theme': 'Theme',
    'language': 'Language',
    'light': 'Light',
    'dark': 'Dark',
    'system': 'System',

    // Currency
    'default_currency': 'Default Currency',
    'multi_currency': 'Multi‑currency',
    'multi_currency_sub': 'Track expenses in multiple currencies',
    'auto_conversion': 'Auto Conversion',
    'auto_conversion_sub': 'Convert to default currency automatically',

    // Reset
    'reset_categories': 'Reset Categories',
    'reset_budgets': 'Reset Budgets',
    'master_reset': 'Master Reset',

    // Reset Dialogs
    'reset_categories_title': 'Reset Categories?',
    'reset_categories_msg':
        'This will remove all custom categories and restore the defaults. Your transactions will not be deleted.',
    'reset_budgets_title': 'Reset Budgets?',
    'reset_budgets_msg':
        'All budget limits will be cleared. Your transactions and categories will remain intact.',
    'master_reset_title': 'Master Reset?',
    'master_reset_msg':
        'This deletes all transactions and budgets. This action cannot be undone.',
    'cancel': 'Cancel',
    'reset': 'Reset',
    'wipe_all': 'Wipe All',

    // Reset Success
    'categories_reset': 'Categories Reset',
    'budgets_reset': 'Budgets Reset',
    'all_data_wiped': 'All data wiped',

    // About & Support
    'app_version': 'App Version',
    'help_faq': 'Help / FAQ',
    'contact_support': 'Contact Support',
    'privacy_policy': 'Privacy Policy',
    'terms_conditions': 'Terms & Conditions',

    // ─── Login Screen ──────────────────────────────────────────
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'email_hint': 'E-mail Id',
    'password_hint': 'Password',
    'enter_password': 'Enter Password',
    'confirm_password': 'Confirm Password',
    'forgot_password': 'Forgot Password ?',
    'login': 'Login',
    'or': 'OR',
    'continue_google': 'Continue With Google',
    'fill_all_fields': 'Please fill in all fields.',
    'passwords_no_match': 'Passwords do not match.',
    'signup_success':
        'Success! A confirmation link has been sent to your email. Please verify to log in.',
    'something_went_wrong': 'Something went wrong. Please try again.',

    // ─── Dashboard — Bottom Nav ────────────────────────────────
    'home': 'Home',
    'transaction': 'Transaction',
    'ai_chat': 'AI chat',

    // ─── Dashboard — HomeView ──────────────────────────────────
    'available_balance': 'Available Balance',
    'expense': 'Expense',
    'income': 'Income',
    'recent_transaction': 'Recent transaction',
    'no_expenses': 'No Expenses',
    'no_recent_txn': 'No recent transactions',
    'others': 'Others',

    // ─── Transactions View ─────────────────────────────────────
    'transaction_details': 'Transaction details',
    'selected': 'Selected',
    'delete_transactions_title': 'Delete Transactions?',
    'delete_transactions_msg_1': 'Are you sure you want to delete ',
    'delete_transactions_msg_2': ' transaction',
    'delete_transactions_msg_3': '? This action cannot be undone.',
    'delete': 'Delete',
    'filter_transactions': 'Filter Transactions',
    'type': 'Type',
    'all': 'All',
    'time': 'Time',
    'all_time': 'All Time',
    'last_7_days': 'Last 7 Days',
    'this_month': 'This Month',
    'apply_filters': 'Apply Filters',
    'no_txn_yet': 'No Transactions Yet',
    'no_txn_hint':
        'Tap the + button below to add your first income or expense.',
    'no_matching_txn': 'No matching transactions',
    'try_adjust_filters': 'Try adjusting your filters.',
    'txn_deleted': 'Transaction',
    'txn_deleted_suffix': ' Deleted',

    // ─── AI Chat View ──────────────────────────────────────────
    'ai_assistant': 'AI Assistant',
    'clear_chat': 'Clear Chat',
    'type_here': 'Type here...',
    'ai_greeting_1': 'Hi ',
    'ai_greeting_2': "! ✨ I'm your FinTrack AI.\nHow can I help you manage your money today?",

    // ─── Profile View ──────────────────────────────────────────
    'add_your_name': 'Add your name',
    'add_your_profession': 'Add your profession',
    'edit_profile': 'Edit Profile',
    'choose_photo': 'Choose Photo',
    'camera': 'Camera',
    'gallery': 'Gallery',
    'name': 'Name',
    'profession': 'Profession',
    'save': 'Save',
    'profile_updated': 'Profile Updated!',
    'upload_failed': 'Upload failed: ',
    'failed_to_update': 'Failed to update: ',
    'enter_your_profession': 'Enter your profession',

    // ─── Custom Drawer ─────────────────────────────────────────
    'monthly_reports': 'Monthly Reports',
    'set_budget': 'Set Budget',
    'notification_alert': 'Notification Alert',
    'help_support_drawer': 'Help & Support',
    'log_out': 'Log out',

    // ─── Notification Settings ─────────────────────────────────
    'notification_settings': 'Notification Settings',
    'alert_preferences': 'Alert Preferences',
    'budget_exceed_alerts': 'Budget Exceed Alerts',
    'budget_exceed_sub': 'Get notified when spending exceeds your budget',
    'daily_spent_details': 'Daily Spent Details',
    'daily_spent_sub': 'Daily breakdown of your spending activity',
    'preferred_alert_time': 'Preferred Alert Time',
    'alert_time_desc': 'Choose the exact time for your notification alert.',
    'save_settings': 'Save Settings',
    'settings_saved': 'Settings Saved!',
    'sign_in_to_save': 'Please sign in to save settings.',

    // ─── Set Budget Screen ─────────────────────────────────────
    'total_monthly_budget': 'Total Monthly Budget',
    'divide_budget': 'Divide your Budget',
    'set_categories': 'Set Categories',
    'set_amount': 'Set Amount',
    'add_categories': 'Add Categories',
    'save_budget': 'Save Budget',
    'enter_total_budget': 'Please enter your total budget',
    'budget_saved': 'Budget saved successfully!',
    'failed_save_budget': 'Failed to save budget: ',

    // ─── Monthly Report Screen ─────────────────────────────────
    'monthly_report': 'Monthly Report',
    'download_report': 'Download Report',
    'export_report': 'Export Report',
    'share_report': 'Share Report',
    'share_report_sub': 'Send via WhatsApp, Email, etc.',
    'save_to_device': 'Save to Device',
    'save_to_device_sub': 'Save CSV to Downloads folder',
    'report_saved': 'Report saved to Downloads!',
    'error_loading_report': 'Error loading report data',

    // ─── Help & Support Screen ─────────────────────────────────
    'help_support': 'Help & Support',
    'faq_title': 'Frequently Asked Questions',
    'faq_q1': 'How do I add a transaction?',
    'faq_a1':
        "Tap the '+' button on the home screen, enter the amount, select a category, and save.",
    'faq_q2': 'How do I set my monthly budget?',
    'faq_a2':
        'Go to the Set Budget screen from the sidebar menu to define your monthly limits.',
    'faq_q3': 'Who is FinTrack for?',
    'faq_a3':
        'FinTrack is designed to help anyone easily track their expenses and manage their personal finances.',
    'need_more_help': 'Need more help?',
    'contact_support_btn': 'Contact Support',
    'could_not_open_email': 'Could not open email app',

    // ─── Forgot Password Screen ────────────────────────────────
    'reset_password': 'Reset Password',
    'forgot_your_password': 'Forgot your password?',
    'forgot_desc':
        "Enter the email address linked to your\naccount and we'll send you a reset link.",
    'email_address': 'Email Address',
    'send_reset_link': 'Send Reset Link',
    'reset_link_sent': 'Reset link sent! Check your email.',
    'please_enter_email': 'Please enter your email',
    'valid_email': 'Please enter a valid email',

    // ─── Update Password Screen ────────────────────────────────
    'set_new_password': 'Set New Password',
    'create_new_password': 'Create a new password',
    'new_password_desc':
        'Your new password must be different\nfrom your previous password.',
    'new_password': 'New Password',
    'confirm_new_password': 'Confirm New Password',
    'enter_new_password': 'Enter new password',
    're_enter_new_password': 'Re-enter new password',
    'update_password': 'Update Password',
    'password_updated': 'Password updated successfully!',
    'enter_password_validation': 'Please enter a new password',
    'password_min_length': 'Password must be at least 6 characters',
    'confirm_password_validation': 'Please confirm your password',

    // ─── Add Transaction Screen ────────────────────────────────
    'expense_label': 'Expense',
    'income_label': 'Income',
    'transaction_method': 'Transaction Method',
    'amount': 'Amount',
    'category': 'Category',
    'notes': 'Notes',
    'enter_custom_category': 'Enter Custom Category',
    'ai_auto_scan': 'AI auto-scan Entry',
    'submit': 'Submit',
    'take_photo': 'Take a Photo',
    'choose_from_gallery': 'Choose from Gallery',
    'enter_amount': 'Please enter an amount.',
    'select_method': 'Please select a transaction method.',
    'txn_saved': 'Transaction saved!',
    'auto_fill_complete': 'Auto-fill complete!',
    'ai_scanning': 'AI is scanning receipt...',

    // ─── Onboarding / Financial Awareness ──────────────────────
    'onboarding_title_1': 'Secure your financial\nfuture with us!',
    'onboarding_sub_1':
        'Let our app handle your bills, while you\nfocus on things that matters the most',
    'onboarding_title_2': 'Build better spending\nhabits',
    'onboarding_sub_2':
        'Log your daily transaction in seconds and build\nhabits that make every rupee count',
    'onboarding_title_3': 'Gain true financial\nawareness!',
    'onboarding_sub_3':
        'Turn your daily spending into clear\nvisual insights',
    'next': 'Next',

    // ─── Common / Shared ───────────────────────────────────────
    'save_failed': 'Save failed: ',
    'delete_failed': 'Delete failed: ',
    'error_prefix': 'Error: ',
  };

  // ── Tamil ────────────────────────────────────────────────────
  static const Map<String, String> _ta = {
    // ─── Settings Screen ───────────────────────────────────────
    'settings': 'அமைப்புகள்',
    'appearance': 'தோற்றம்',
    'currency': 'நாணயம்',
    'reset_options': 'மீட்டமை விருப்பங்கள்',
    'about': 'பற்றி',
    'theme': 'தீம்',
    'language': 'மொழி',
    'light': 'Light',
    'dark': 'Dark',
    'system': 'System',
    'default_currency': 'இயல்பு நாணயம்',
    'multi_currency': 'பல நாணயம்',
    'multi_currency_sub': 'பல நாணயங்களில் செலவுகளைக் கண்காணிக்கவும்',
    'auto_conversion': 'தானியங்கி மாற்றம்',
    'auto_conversion_sub': 'இயல்பு நாணயத்திற்கு தானாக மாற்றவும்',
    'reset_categories': 'வகைகளை மீட்டமை',
    'reset_budgets': 'பட்ஜெட்களை மீட்டமை',
    'master_reset': 'முழு மீட்டமை',
    'reset_categories_title': 'வகைகளை மீட்டமைக்கவா?',
    'reset_categories_msg':
        'இது அனைத்து தனிப்பயன் வகைகளையும் அகற்றி இயல்புநிலையை மீட்டமைக்கும். உங்கள் பரிவர்த்தனைகள் நீக்கப்படாது.',
    'reset_budgets_title': 'பட்ஜெட்களை மீட்டமைக்கவா?',
    'reset_budgets_msg':
        'அனைத்து பட்ஜெட் வரம்புகளும் அழிக்கப்படும். உங்கள் பரிவர்த்தனைகள் மற்றும் வகைகள் அப்படியே இருக்கும்.',
    'master_reset_title': 'முழு மீட்டமையா?',
    'master_reset_msg':
        'இது அனைத்து பரிவர்த்தனைகள் மற்றும் பட்ஜெட்களை நீக்கும். இந்த செயலை மாற்ற முடியாது.',
    'cancel': 'ரத்து',
    'reset': 'மீட்டமை',
    'wipe_all': 'அனைத்தையும் அழி',
    'categories_reset': 'வகைகள் மீட்டமைக்கப்பட்டன',
    'budgets_reset': 'பட்ஜெட்கள் மீட்டமைக்கப்பட்டன',
    'all_data_wiped': 'அனைத்து தரவும் அழிக்கப்பட்டது',
    'app_version': 'பதிப்பு',
    'help_faq': 'உதவி / FAQ',
    'contact_support': 'ஆதரவைத் தொடர்பு',
    'privacy_policy': 'தனியுரிமைக் கொள்கை',
    'terms_conditions': 'விதிமுறைகள் & நிபந்தனைகள்',

    // ─── Login Screen ──────────────────────────────────────────
    'sign_in': 'உள்நுழை',
    'sign_up': 'பதிவு செய்',
    'email_hint': 'மின்னஞ்சல்',
    'password_hint': 'கடவுச்சொல்',
    'enter_password': 'கடவுச்சொல் உள்ளிடவும்',
    'confirm_password': 'கடவுச்சொல் உறுதிசெய்',
    'forgot_password': 'கடவுச்சொல் மறந்துவிட்டதா?',
    'login': 'உள்நுழை',
    'or': 'அல்லது',
    'continue_google': 'Google வழியாக தொடரவும்',
    'fill_all_fields': 'அனைத்து புலங்களையும் நிரப்பவும்.',
    'passwords_no_match': 'கடவுச்சொற்கள் பொருந்தவில்லை.',
    'signup_success':
        'வெற்றி! உறுதிப்படுத்தல் இணைப்பு உங்கள் மின்னஞ்சலுக்கு அனுப்பப்பட்டது. உள்நுழைய சரிபார்க்கவும்.',
    'something_went_wrong': 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.',

    // ─── Dashboard — Bottom Nav ────────────────────────────────
    'home': 'முகப்பு',
    'transaction': 'பரிவர்த்தனை',
    'ai_chat': 'AI அரட்டை',

    // ─── Dashboard — HomeView ──────────────────────────────────
    'available_balance': 'கிடைக்கும் இருப்பு',
    'expense': 'செலவு',
    'income': 'வருமானம்',
    'recent_transaction': 'சமீபத்திய பரிவர்த்தனை',
    'no_expenses': 'செலவுகள் இல்லை',
    'no_recent_txn': 'சமீபத்திய பரிவர்த்தனைகள் இல்லை',
    'others': 'மற்றவை',

    // ─── Transactions View ─────────────────────────────────────
    'transaction_details': 'பரிவர்த்தனை விவரங்கள்',
    'selected': 'தேர்ந்தெடுக்கப்பட்டது',
    'delete_transactions_title': 'பரிவர்த்தனைகளை நீக்கவா?',
    'delete_transactions_msg_1': 'நீங்கள் ',
    'delete_transactions_msg_2': ' பரிவர்த்தனை',
    'delete_transactions_msg_3': 'களை நீக்க விரும்புகிறீர்களா? இந்த செயலை மாற்ற முடியாது.',
    'delete': 'நீக்கு',
    'filter_transactions': 'பரிவர்த்தனைகளை வடிகட்டு',
    'type': 'வகை',
    'all': 'அனைத்தும்',
    'time': 'நேரம்',
    'all_time': 'முழு நேரம்',
    'last_7_days': 'கடந்த 7 நாட்கள்',
    'this_month': 'இந்த மாதம்',
    'apply_filters': 'வடிகட்டிகளைப் பயன்படுத்து',
    'no_txn_yet': 'இன்னும் பரிவர்த்தனைகள் இல்லை',
    'no_txn_hint':
        'உங்கள் முதல் வருமானம் அல்லது செலவை சேர்க்க கீழே உள்ள + பொத்தானைத் தட்டவும்.',
    'no_matching_txn': 'பொருந்தும் பரிவர்த்தனைகள் இல்லை',
    'try_adjust_filters': 'உங்கள் வடிகட்டிகளை மாற்றி முயற்சிக்கவும்.',
    'txn_deleted': 'பரிவர்த்தனை',
    'txn_deleted_suffix': ' நீக்கப்பட்டது',

    // ─── AI Chat View ──────────────────────────────────────────
    'ai_assistant': 'AI உதவியாளர்',
    'clear_chat': 'அரட்டையை அழி',
    'type_here': 'இங்கே தட்டச்சு செய்யவும்...',
    'ai_greeting_1': 'வணக்கம் ',
    'ai_greeting_2': "! ✨ நான் உங்கள் FinTrack AI.\nஇன்று உங்கள் பணத்தை நிர்வகிக்க நான் எப்படி உதவ முடியும்?",

    // ─── Profile View ──────────────────────────────────────────
    'add_your_name': 'உங்கள் பெயரைச் சேர்க்கவும்',
    'add_your_profession': 'உங்கள் தொழிலைச் சேர்க்கவும்',
    'edit_profile': 'சுயவிவரத்தைத் திருத்து',
    'choose_photo': 'புகைப்படம் தேர்வு',
    'camera': 'கேமரா',
    'gallery': 'கேலரி',
    'name': 'பெயர்',
    'profession': 'தொழில்',
    'save': 'சேமி',
    'profile_updated': 'சுயவிவரம் புதுப்பிக்கப்பட்டது!',
    'upload_failed': 'பதிவேற்றம் தோல்வி: ',
    'failed_to_update': 'புதுப்பிக்க இயலவில்லை: ',
    'enter_your_profession': 'உங்கள் தொழிலை உள்ளிடவும்',

    // ─── Custom Drawer ─────────────────────────────────────────
    'monthly_reports': 'மாத அறிக்கைகள்',
    'set_budget': 'பட்ஜெட் அமை',
    'notification_alert': 'அறிவிப்பு எச்சரிக்கை',
    'help_support_drawer': 'உதவி & ஆதரவு',
    'log_out': 'வெளியேறு',

    // ─── Notification Settings ─────────────────────────────────
    'notification_settings': 'அறிவிப்பு அமைப்புகள்',
    'alert_preferences': 'எச்சரிக்கை விருப்பங்கள்',
    'budget_exceed_alerts': 'பட்ஜெட் மீறல் எச்சரிக்கைகள்',
    'budget_exceed_sub': 'செலவு பட்ஜெட்டை மீறும்போது அறிவிப்பு பெறவும்',
    'daily_spent_details': 'தினசரி செலவு விவரங்கள்',
    'daily_spent_sub': 'உங்கள் செலவு நடவடிக்கையின் தினசரி பகுப்பாய்வு',
    'preferred_alert_time': 'விரும்பிய எச்சரிக்கை நேரம்',
    'alert_time_desc': 'உங்கள் அறிவிப்பு எச்சரிக்கைக்கான நேரத்தைத் தேர்ந்தெடுக்கவும்.',
    'save_settings': 'அமைப்புகளைச் சேமி',
    'settings_saved': 'அமைப்புகள் சேமிக்கப்பட்டன!',
    'sign_in_to_save': 'அமைப்புகளைச் சேமிக்க உள்நுழையவும்.',

    // ─── Set Budget Screen ─────────────────────────────────────
    'total_monthly_budget': 'மொத்த மாத பட்ஜெட்',
    'divide_budget': 'உங்கள் பட்ஜெட்டைப் பிரிக்கவும்',
    'set_categories': 'வகைகளை அமை',
    'set_amount': 'தொகையை அமை',
    'add_categories': 'வகைகளைச் சேர்',
    'save_budget': 'பட்ஜெட் சேமி',
    'enter_total_budget': 'உங்கள் மொத்த பட்ஜெட்டை உள்ளிடவும்',
    'budget_saved': 'பட்ஜெட் வெற்றிகரமாக சேமிக்கப்பட்டது!',
    'failed_save_budget': 'பட்ஜெட் சேமிக்க இயலவில்லை: ',

    // ─── Monthly Report Screen ─────────────────────────────────
    'monthly_report': 'மாத அறிக்கை',
    'download_report': 'அறிக்கையை பதிவிறக்கு',
    'export_report': 'அறிக்கையை ஏற்றுமதி செய்',
    'share_report': 'அறிக்கையைப் பகிர்',
    'share_report_sub': 'WhatsApp, மின்னஞ்சல் போன்றவை வழியாக அனுப்பவும்',
    'save_to_device': 'சாதனத்தில் சேமி',
    'save_to_device_sub': 'CSV ஐ பதிவிறக்கங்கள் கோப்புறையில் சேமிக்கவும்',
    'report_saved': 'அறிக்கை பதிவிறக்கங்களில் சேமிக்கப்பட்டது!',
    'error_loading_report': 'அறிக்கை தரவை ஏற்றுவதில் பிழை',

    // ─── Help & Support Screen ─────────────────────────────────
    'help_support': 'உதவி & ஆதரவு',
    'faq_title': 'அடிக்கடி கேட்கப்படும் கேள்விகள்',
    'faq_q1': 'பரிவர்த்தனையை எவ்வாறு சேர்ப்பது?',
    'faq_a1':
        "முகப்புத் திரையில் '+' பொத்தானைத் தட்டி, தொகையை உள்ளிட்டு, வகையைத் தேர்வு செய்து, சேமிக்கவும்.",
    'faq_q2': 'மாத பட்ஜெட்டை எவ்வாறு அமைப்பது?',
    'faq_a2':
        'பக்கப்பட்டி மெனுவிலிருந்து பட்ஜெட் அமை திரைக்குச் சென்று உங்கள் மாத வரம்புகளை வரையறுக்கவும்.',
    'faq_q3': 'FinTrack யாருக்கானது?',
    'faq_a3':
        'FinTrack செலவுகளை எளிதாகக் கண்காணிக்கவும் தனிநபர் நிதியை நிர்வகிக்கவும் யாருக்கும் உதவ வடிவமைக்கப்பட்டது.',
    'need_more_help': 'மேலும் உதவி தேவையா?',
    'contact_support_btn': 'ஆதரவைத் தொடர்புகொள்',
    'could_not_open_email': 'மின்னஞ்சல் பயன்பாட்டைத் திறக்க முடியவில்லை',

    // ─── Forgot Password Screen ────────────────────────────────
    'reset_password': 'கடவுச்சொல் மீட்டமை',
    'forgot_your_password': 'கடவுச்சொல் மறந்துவிட்டதா?',
    'forgot_desc':
        'உங்கள் கணக்குடன் இணைக்கப்பட்ட மின்னஞ்சல் முகவரியை\nஉள்ளிடவும், மீட்டமை இணைப்பை அனுப்புவோம்.',
    'email_address': 'மின்னஞ்சல் முகவரி',
    'send_reset_link': 'மீட்டமை இணைப்பை அனுப்பு',
    'reset_link_sent': 'மீட்டமை இணைப்பு அனுப்பப்பட்டது! உங்கள் மின்னஞ்சலைச் சரிபார்க்கவும்.',
    'please_enter_email': 'உங்கள் மின்னஞ்சலை உள்ளிடவும்',
    'valid_email': 'சரியான மின்னஞ்சலை உள்ளிடவும்',

    // ─── Update Password Screen ────────────────────────────────
    'set_new_password': 'புதிய கடவுச்சொல் அமை',
    'create_new_password': 'புதிய கடவுச்சொல்லை உருவாக்கவும்',
    'new_password_desc':
        'உங்கள் புதிய கடவுச்சொல் முந்தைய\nகடவுச்சொல்லிலிருந்து வேறுபட்டதாக இருக்க வேண்டும்.',
    'new_password': 'புதிய கடவுச்சொல்',
    'confirm_new_password': 'புதிய கடவுச்சொல் உறுதிசெய்',
    'enter_new_password': 'புதிய கடவுச்சொல் உள்ளிடவும்',
    're_enter_new_password': 'புதிய கடவுச்சொல் மீண்டும் உள்ளிடவும்',
    'update_password': 'கடவுச்சொல் புதுப்பி',
    'password_updated': 'கடவுச்சொல் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!',
    'enter_password_validation': 'புதிய கடவுச்சொல்லை உள்ளிடவும்',
    'password_min_length': 'கடவுச்சொல் குறைந்தது 6 எழுத்துகளாக இருக்க வேண்டும்',
    'confirm_password_validation': 'உங்கள் கடவுச்சொல்லை உறுதிசெய்யவும்',

    // ─── Add Transaction Screen ────────────────────────────────
    'expense_label': 'செலவு',
    'income_label': 'வருமானம்',
    'transaction_method': 'பரிவர்த்தனை முறை',
    'amount': 'தொகை',
    'category': 'வகை',
    'notes': 'குறிப்புகள்',
    'enter_custom_category': 'தனிப்பயன் வகையை உள்ளிடவும்',
    'ai_auto_scan': 'AI தானியங்கி ஸ்கேன்',
    'submit': 'சமர்ப்பி',
    'take_photo': 'புகைப்படம் எடு',
    'choose_from_gallery': 'கேலரியிலிருந்து தேர்வு',
    'enter_amount': 'தொகையை உள்ளிடவும்.',
    'select_method': 'பரிவர்த்தனை முறையைத் தேர்ந்தெடுக்கவும்.',
    'txn_saved': 'பரிவர்த்தனை சேமிக்கப்பட்டது!',
    'auto_fill_complete': 'தானியங்கி நிரப்பு முடிந்தது!',
    'ai_scanning': 'AI ரசீதை ஸ்கேன் செய்கிறது...',

    // ─── Onboarding / Financial Awareness ──────────────────────
    'onboarding_title_1': 'எங்களுடன் உங்கள் நிதி\nஎதிர்காலத்தைப் பாதுகாக்கவும்!',
    'onboarding_sub_1':
        'உங்கள் பில்களை எங்கள் பயன்பாடு கையாளட்டும்,\nமுக்கியமான விஷயங்களில் நீங்கள் கவனம் செலுத்துங்கள்',
    'onboarding_title_2': 'சிறந்த செலவு\nபழக்கங்களை உருவாக்குங்கள்',
    'onboarding_sub_2':
        'உங்கள் தினசரி பரிவர்த்தனையை நொடிகளில் பதிவு செய்து\nஒவ்வொரு ரூபாயும் மதிப்புள்ளதாக்குங்கள்',
    'onboarding_title_3': 'உண்மையான நிதி\nவிழிப்புணர்வைப் பெறுங்கள்!',
    'onboarding_sub_3':
        'உங்கள் தினசரி செலவை தெளிவான\nகாட்சி நுண்ணறிவுகளாக மாற்றுங்கள்',
    'next': 'அடுத்தது',

    // ─── Common / Shared ───────────────────────────────────────
    'save_failed': 'சேமிப்பு தோல்வி: ',
    'delete_failed': 'நீக்குதல் தோல்வி: ',
    'error_prefix': 'பிழை: ',
  };
}
