/// Mirrors app/models/moderation.py -> ReportReason. Value on the wire
/// is the lowercase enum value (e.g. "cheating").
enum ReportReason {
  cheating,
  harassment,
  abusiveLanguage,
  noShow,
  matchFixing,
  impersonation,
  spam,
  other;

  String get wireValue => switch (this) {
    ReportReason.cheating => 'cheating',
    ReportReason.harassment => 'harassment',
    ReportReason.abusiveLanguage => 'abusive_language',
    ReportReason.noShow => 'no_show',
    ReportReason.matchFixing => 'match_fixing',
    ReportReason.impersonation => 'impersonation',
    ReportReason.spam => 'spam',
    ReportReason.other => 'other',
  };

  String get label => switch (this) {
    ReportReason.cheating => 'Cheating',
    ReportReason.harassment => 'Harassment',
    ReportReason.abusiveLanguage => 'Abusive Language',
    ReportReason.noShow => 'No Show',
    ReportReason.matchFixing => 'Match Fixing',
    ReportReason.impersonation => 'Impersonation',
    ReportReason.spam => 'Spam',
    ReportReason.other => 'Other',
  };
}

/// Mirrors app/models/moderation.py -> ReportTargetType.
enum ReportTargetType {
  player,
  team,
  tournament;

  String get wireValue => switch (this) {
    ReportTargetType.player => 'player',
    ReportTargetType.team => 'team',
    ReportTargetType.tournament => 'tournament',
  };
}
