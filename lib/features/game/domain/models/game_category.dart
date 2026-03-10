class GameCategory {
  const GameCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.promptHint,
  });

  final String id;
  final String title;
  final String subtitle;
  final String promptHint;

  static const List<GameCategory> presets = [
    GameCategory(
      id: 'relationship_chaos',
      title: 'Relationship Chaos',
      subtitle: 'Petty BF/GF drama with spectacularly bad timing.',
      promptHint: 'boyfriend and girlfriend drama with social-media chaos',
    ),
    GameCategory(
      id: 'friendship_meltdown',
      title: 'Friendship Meltdown',
      subtitle: 'Group-chat betrayals and impulsive loyalty tests.',
      promptHint: 'friendship arguments, misread signals, chaotic humor',
    ),
    GameCategory(
      id: 'daily_absurdity',
      title: 'Daily Absurdity',
      subtitle: 'Small life disasters that snowball into nonsense.',
      promptHint: 'funny everyday life scenario with escalating consequences',
    ),
  ];

  static GameCategory fallbackById(String id) {
    return presets.firstWhere(
      (category) => category.id == id,
      orElse: () => presets.first,
    );
  }
}
