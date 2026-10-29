import 'package:exhale/core/presentation/app_icons.dart';
import 'package:exhale/core/theme/app_spacing.dart';
import 'package:exhale/core/theme/theme_context_extension.dart';
import 'package:exhale/core/widgets/number_stepper.dart';
import 'package:exhale/features/habit/domain/entities/habit.dart';
import 'package:exhale/features/habit/domain/validation/habit_validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CostCard extends StatefulWidget {
  const CostCard({
    required this.habit,
    required this.currencySymbol,
    required this.unitsPerContainer,
    required this.showPriceError,
    required this.onPriceChanged,
    required this.onUnitsPerContainerChanged,
    this.initialPriceText = '',
    super.key,
  });

  final Habit habit;
  final String currencySymbol;
  final int unitsPerContainer;
  final bool showPriceError;
  final String initialPriceText;
  final ValueChanged<String> onPriceChanged;
  final ValueChanged<int> onUnitsPerContainerChanged;

  @override
  State<CostCard> createState() => _CostCardState();
}

class _CostCardState extends State<CostCard> {
  bool _expanded = true;
  late final TextEditingController _price = TextEditingController(
    text: widget.initialPriceText,
  );

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final habit = widget.habit;
    final container = habit.container;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                spacing: AppSpacing.gutterSm,
                children: [
                  Icon(AppIcons.savings, color: colors.primary),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What it costs', style: text.titleLarge),
                        Text(
                          'Optional. Used to show money saved.',
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                spacing: AppSpacing.gutterSm,
                children: [
                  TextField(
                    controller: _price,
                    onChanged: widget.onPriceChanged,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Price per ${container ?? habit.unit}',
                      prefixText: '${widget.currencySymbol} ',
                      hintText: container == null ? '3.50' : '14.50',
                      errorText: widget.showPriceError
                          ? 'Enter a valid price'
                          : null,
                    ),
                  ),
                  if (container != null)
                    NumberStepper(
                      value: widget.unitsPerContainer,
                      min: 1,
                      max: HabitValidation.maxUnitsPerContainer,
                      onChanged: widget.onUnitsPerContainerChanged,
                      unit: habit.shortUnits,
                      caption: 'per $container',
                      semanticLabel: '${habit.units} per $container',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
