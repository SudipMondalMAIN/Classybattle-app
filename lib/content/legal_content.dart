import '../screens/legal_info_screen.dart' show InfoSection;

/// Content shown on Settings > About > About ClassyBattle.
const aboutSections = <InfoSection>[
  InfoSection(
    'What is ClassyBattle',
    'ClassyBattle is a competitive eSports tournament platform. Players '
        'join solo or squad tournaments across supported games, compete in '
        'scheduled matches, and win real cash prizes based on their '
        'in-game performance.',
  ),
  InfoSection(
    'How it works',
    'Browse live and upcoming tournaments, join with your in-game profile, '
        'and get room details (room ID/password) once they\'re published '
        'ahead of the match. After the match, results are reviewed and '
        'prize payouts are credited to your ClassyBattle wallet.',
  ),
  InfoSection(
    'Wallet & payments',
    'Add money to your wallet to pay tournament entry fees, and withdraw '
        'your winnings whenever you like, subject to the minimum/maximum '
        'limits shown on the Withdraw screen. Every credit and debit is '
        'recorded in your transaction history.',
  ),
  InfoSection(
    'Fair play',
    'ClassyBattle uses moderation and anti-cheat tooling to keep matches '
        'fair. Reported players are reviewed by our team, and confirmed '
        'violations can result in match disqualification or account '
        'action.',
  ),
];

/// Content shown on Settings > About > Terms & Conditions.
///
/// NOTE: this is starter/placeholder legal copy written to match how
/// the app actually works (tournaments, entry fees, wallet, prize
/// payouts, withdrawals). It is not a substitute for review by a
/// qualified lawyer before shipping — please have counsel review and
/// adjust this (especially the eligibility, refund, and liability
/// sections) for your jurisdiction before relying on it in production.
const termsSections = <InfoSection>[
  InfoSection(
    '1. Acceptance of terms',
    'By creating a ClassyBattle account or joining a tournament, you '
        'agree to these Terms & Conditions and to our Privacy Policy. If '
        'you don\'t agree, please don\'t use the app.',
  ),
  InfoSection(
    '2. Eligibility',
    'You must be able to form a binding legal agreement in your '
        'jurisdiction to use ClassyBattle, and you\'re responsible for '
        'making sure participating in paid tournaments and receiving cash '
        'prizes is lawful where you live. One account is permitted per '
        'person; duplicate accounts may be suspended.',
  ),
  InfoSection(
    '3. Tournaments & entry fees',
    'Joining a paid tournament deducts the listed entry fee from your '
        'wallet at the time you join. Tournament rules, formats, and '
        'schedules are set by the organizer and shown on each tournament\'s '
        'details screen — read them before joining. ClassyBattle may '
        'reschedule or cancel a tournament (e.g. for insufficient '
        'participants); entry fees for cancelled tournaments are refunded '
        'to your wallet.',
  ),
  InfoSection(
    '4. Fair play & conduct',
    'Cheating, use of unauthorized third-party software, match-fixing, '
        'account sharing, and abusive conduct toward other players or '
        'staff are prohibited. Violations may result in match '
        'disqualification, forfeiture of prizes for the affected match, '
        'or suspension of your account, at ClassyBattle\'s discretion '
        'after review.',
  ),
  InfoSection(
    '5. Wallet, prizes & withdrawals',
    'Prize payouts for tournaments you win are credited to your '
        'ClassyBattle wallet after results are reviewed and approved. '
        'Withdrawals are subject to the minimum/maximum limits shown in '
        'the app and are processed after admin review — payout isn\'t '
        'instant. ClassyBattle is not responsible for delays caused by '
        'your payment provider.',
  ),
  InfoSection(
    '6. Account suspension & termination',
    'We may suspend or terminate an account for violations of these '
        'terms, fraudulent activity, or chargebacks. Where reasonably '
        'possible, we\'ll let you know why. Wallet balances tied to an '
        'account under investigation may be held pending review.',
  ),
  InfoSection(
    '7. Limitation of liability',
    'ClassyBattle is provided "as is". We aren\'t liable for losses '
        'arising from service interruptions, third-party payment or '
        'network issues, or a player\'s own device/connection problems '
        'during a match, except where required by applicable law.',
  ),
  InfoSection(
    '8. Changes to these terms',
    'We may update these terms from time to time. Material changes will '
        'be reflected here with an updated date; continuing to use '
        'ClassyBattle after changes take effect means you accept the '
        'updated terms.',
  ),
  InfoSection(
    '9. Contact',
    'Questions about these terms can be sent through Settings > Support '
        '(Live Chat or Report a Problem).',
  ),
];

/// Content shown on Settings > About > Privacy Policy.
///
/// NOTE: same caveat as the Terms content above -- this is a good-faith
/// starting point grounded in what the app actually collects/does
/// (account info, wallet/payment records, game profile data, push
/// notifications), not a substitute for legal review before launch.
const privacySections = <InfoSection>[
  InfoSection(
    '1. Information we collect',
    'Account details you provide (name, email, phone, in-game profile '
        'IDs), tournament and match activity, wallet transaction records, '
        'payment method metadata (not full card numbers -- those are '
        'handled by our payment processor), and device information used '
        'for push notifications.',
  ),
  InfoSection(
    '2. How we use your information',
    'To run your account, process tournament registrations and entry '
        'fees, calculate and pay out prizes, show you relevant '
        'tournaments and notifications, investigate reported fair-play '
        'issues, and provide support when you contact us.',
  ),
  InfoSection(
    '3. Payment data',
    'Payments and withdrawals are processed through our payment '
        'partners. ClassyBattle stores transaction records (amount, '
        'status, reference) needed for your wallet history, but does not '
        'store your full card or bank details.',
  ),
  InfoSection(
    '4. Sharing',
    'We don\'t sell your personal data. Information is shared only with '
        'service providers who help us run the app (payments, push '
        'notifications, email, cloud hosting) under agreements that '
        'restrict their use of it, or when required by law.',
  ),
  InfoSection(
    '5. Data retention',
    'We keep account and transaction data for as long as your account is '
        'active and as needed to meet legal, tax, and dispute-resolution '
        'obligations after that.',
  ),
  InfoSection(
    '6. Your choices',
    'You can update your profile from Settings > Edit Profile, control '
        'push/in-app/email notifications from Settings > Notifications, '
        'and request account deletion or a copy of your data through '
        'Settings > Support.',
  ),
  InfoSection(
    '7. Security',
    'We use industry-standard measures (encrypted connections, hashed '
        'passwords, access controls) to protect your data, but no system '
        'is 100% secure -- please use a strong, unique password.',
  ),
  InfoSection(
    '8. Changes to this policy',
    'We may update this policy as the app evolves. Material changes will '
        'be reflected here with an updated date.',
  ),
  InfoSection(
    '9. Contact',
    'Privacy questions or data requests can be sent through Settings > '
        'Support (Live Chat or Report a Problem).',
  ),
];
