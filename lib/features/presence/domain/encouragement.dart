import 'dart:math';

/// Short lines for the wait between uses, shown on Home and in the Live
/// Activity. The first 7 are Home's quotes. None suggests using.
const List<String> encouragementLines = [
  'Every breath is a fresh decision.',
  'One fewer today is a real win.',
  'Cravings pass. You stay.',
  'Slow is still forward.',
  'Notice the urge, then let it go by.',
  'Each smaller day adds up.',
  'Progress, not perfection.',
  'The urge peaks, then it fades.',
  'Breathe in. Breathe out. Again.',
  'Waiting is the work. You are doing it.',
  'This feeling will pass on its own.',
  'A pause is a small victory.',
  'You are stronger than one moment.',
  'Every minute you wait counts.',
  'Let the urge come and go.',
  'Calm is a skill. You are learning it.',
  'Today is shaping tomorrow.',
  'More space, more freedom.',
  'Your body notices every gap.',
  'One breath at a time.',
  'Stay curious about the urge.',
  'Drink some water. Stretch a little.',
  'Go for a short walk.',
  'Fewer, then fewer, then none.',
  'Your quit date is getting closer.',
  'This is what change feels like.',
  'Be patient with yourself.',
  'Steady wins this.',
  'You chose this plan for a reason.',
  'The habit is loosening its grip.',
  'Ride the wave. It always breaks.',
  'Ten slow breaths can change a lot.',
  'Nothing to do right now but breathe.',
  'Go easy on yourself today.',
  'A busy hand quiets the urge.',
  'Name the feeling. Let it be.',
  'Your future self says thank you.',
  'Discomfort now, freedom later.',
  'Each gap makes waiting easier.',
  'Urges are loud but brief.',
  'Proud of you for waiting.',
  'You are rewriting a routine.',
  'Keep going. It gets lighter.',
  'Notice how far you have come.',
  'Trust the plan. It tapers gently.',
  'Make tea. Take your time.',
  'Hold steady. This moment passes.',
  'Every day on plan builds trust.',
  'Sit with it. It softens.',
  'Freedom is built in small gaps.',
  'You are in charge, not the habit.',
  'Breathe slow. Shoulders down.',
  'Text a friend while you wait.',
  'Quiet the mind, steady the hands.',
  'Change is happening, even today.',
  'Each wait is a vote for you.',
  'A calmer day starts with one pause.',
  'Look up. Look around. Breathe.',
  'You have done harder things.',
  'Keep the streak of small wins.',
];

/// The two lines a Live Activity shows: one while counting down, one once it
/// is on schedule.
typedef LinePair = ({String counting, String waiting});

/// Two different lines, neither from [last].
LinePair pickLinePair(Random random, {LinePair? last}) {
  final pool = [
    for (final line in encouragementLines)
      if (line != last?.counting && line != last?.waiting) line,
  ];
  final counting = pool.removeAt(random.nextInt(pool.length));
  return (counting: counting, waiting: pool[random.nextInt(pool.length)]);
}
