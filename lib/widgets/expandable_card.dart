import 'package:flutter/material.dart';
import 'package:worldshift_assistant/utils/catalog_card_stripe.dart';
import 'package:worldshift_assistant/utils/unit_icon_candidates.dart';
import 'package:worldshift_assistant/utils/utils.dart';
import 'package:worldshift_assistant/widgets/item_description_widget.dart';
import 'package:worldshift_assistant/widgets/resolved_mini_asset_image.dart';

/// Tinte del hueco del icono en el Builder cuando [ItemCompleteFrame.darkInterior] es true.
enum BuilderHudInterior {
  human,
  mutant,
  alien,
}

RadialGradient _darkHudGradient(BuilderHudInterior kind) {
  switch (kind) {
    case BuilderHudInterior.human:
      return const RadialGradient(
        center: Alignment(0, -0.15),
        radius: 1.05,
        colors: [
          Color(0xFF3A4A5C),
          Color(0xFF141820),
        ],
        stops: [0.0, 1.0],
      );
    case BuilderHudInterior.mutant:
      return const RadialGradient(
        center: Alignment(0.05, -0.12),
        radius: 1.08,
        colors: [
          Color(0xFF5A4A38),
          Color(0xFF120E0A),
        ],
        stops: [0.0, 1.0],
      );
    case BuilderHudInterior.alien:
      return const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.05,
        colors: [
          Color(0xFF143828),
          Color(0xFF020503),
        ],
        stops: [0.0, 1.0],
      );
  }
}

// --- Shared item-card detail helpers (list card + preview sheet) ---

Color _itemCatalogReadableAccent(Color base) {
  final darkness = base.computeLuminance() > 0.6 ? 0.72 : 0.42;
  return Color.alphaBlend(
    Colors.black.withValues(alpha: darkness),
    base,
  );
}

String _itemCatalogSourceText(String map, Map<String, dynamic> itemData) {
  final m = map.trim();
  final obtainedFrom = '${itemData['obtainedFrom'] ?? ''}'.trim();
  if (m.isNotEmpty && obtainedFrom.isNotEmpty) {
    return '$m · $obtainedFrom';
  }
  if (m.isNotEmpty) {
    return m;
  }
  if (obtainedFrom.isNotEmpty) {
    return obtainedFrom;
  }
  return '';
}

String _itemCatalogFormatUnitLabel(String unitKey) {
  final rawLabel = getUnitValue(unitKey).replaceAll('_', ' ').trim();
  return rawLabel.replaceAllMapped(
    RegExp(r'(?<=[a-z])(?=[A-Z])'),
    (_) => ' ',
  );
}

List<_AffectedUnitChipData> _itemCatalogAffectedUnits(dynamic rawAttributes) {
  if (rawAttributes is! Map<String, dynamic> || rawAttributes.isEmpty) {
    return const [];
  }

  final seen = <String>{};
  final affectedUnits = <_AffectedUnitChipData>[];

  for (final entry in rawAttributes.entries) {
    final key = entry.key.trim();
    if (key.isEmpty || !seen.add(key)) {
      continue;
    }
    if (entry.value is Map<String, dynamic>) {
      affectedUnits.add(
        _AffectedUnitChipData(
          label: _itemCatalogFormatUnitLabel(entry.key),
          assetCandidates: unitIconAssetCandidates(entry.key),
        ),
      );
    }
  }

  return affectedUnits;
}

List<_PreviewStatGroup> _itemCatalogPreviewGroups(dynamic rawAttributes) {
  if (rawAttributes is! Map<String, dynamic>) {
    return const [];
  }

  final groups = <_PreviewStatGroup>[];
  for (final entry in rawAttributes.entries) {
    final unitName = _itemCatalogFormatUnitLabel(entry.key);
    final value = entry.value;

    if (value is Map<String, dynamic>) {
      final lines = <_PreviewStatLine>[];
      for (final attrEntry in value.entries) {
        final amount = '${attrEntry.value}';
        lines.add(
          _PreviewStatLine(
            amount: amount.startsWith('-') ? amount : '+$amount',
            attribute: getAttributeValue(attrEntry.key),
          ),
        );
      }
      if (lines.isNotEmpty) {
        groups.add(_PreviewStatGroup(unit: unitName, lines: lines));
      }
    } else {
      groups.add(
        _PreviewStatGroup(
          unit: unitName,
          lines: [
            _PreviewStatLine(
              amount: '$value',
              attribute: '',
            ),
          ],
        ),
      );
    }
  }
  return groups;
}

/// Light bottom sheet matching skill-tree node detail (background, radius).
void showItemCatalogDetailSheet(
  BuildContext context, {
  required String name,
  required String map,
  required String rarity,
  required String obtainedFrom,
  required Map<String, dynamic> itemData,
  VoidCallback? onPrimaryAction,
  String primaryActionLabel = 'Equip',
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFFF8F9FA),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: ItemCatalogDetailSheetBody(
              name: name,
              map: map,
              rarity: rarity,
              obtainedFrom: obtainedFrom,
              itemData: itemData,
              onPrimaryAction: onPrimaryAction == null
                  ? null
                  : () {
                      Navigator.of(sheetContext).pop();
                      onPrimaryAction();
                    },
              primaryActionLabel: primaryActionLabel,
            ),
          ),
        ),
      );
    },
  );
}

class ExpandableCard extends StatefulWidget {
  final String name;
  final String map;
  final String rarity;
  final String obtainedFrom;
  final Map<String, dynamic> itemData;
  /// When set (e.g. Builder equip picker), shows a primary action without changing expand/collapse.
  final VoidCallback? onSelect;
  final String selectLabel;

  const ExpandableCard({
    Key? key,
    required this.name,
    required this.map,
    required this.rarity,
    required this.obtainedFrom,
    required this.itemData,
    this.onSelect,
    this.selectLabel = 'Equip',
  }) : super(key: key);

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final rarityColor = getRarityColor(widget.itemData['rarity']);
    final readableAccent = _itemCatalogReadableAccent(rarityColor);
    final previewGroups = _itemCatalogPreviewGroups(widget.itemData['attributes']);
    final affectedUnits = _itemCatalogAffectedUnits(
      widget.itemData['attributes'],
    );
    final sourceText = _itemCatalogSourceText(widget.map, widget.itemData);
    final hasSourceText = sourceText.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CatalogCardStripe.forRarityColor(rarityColor),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      rarityColor.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ItemCompleteFrame(
                              slot: widget.itemData['slot'],
                              rarity: widget.rarity,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: readableAccent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                          height: 1.1,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (widget.onSelect != null) ...[
                                      _SelectActionChip(
                                        label: widget.selectLabel,
                                        onPressed: widget.onSelect!,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    _IconButtonChip(
                                      icon: _isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      onPressed: () {
                                        setState(() {
                                          _isExpanded = !_isExpanded;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _InfoChip(
                                      label: rarityToString(widget.rarity),
                                      color: rarityColor,
                                      icon: Icons.stars_rounded,
                                    ),
                                    _InfoChip(
                                      label: getSlotValueOrDescription(
                                        widget.itemData['slot'],
                                      ),
                                      color: const Color(0xFF5E6678),
                                      icon: Icons.category_outlined,
                                    ),
                                  ],
                                ),
                                if (affectedUnits.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: affectedUnits
                                        .map(
                                          (unit) => _UnitInfoChip(
                                            label: unit.label,
                                            color: const Color(0xFF5E6678),
                                            assetCandidates:
                                                unit.assetCandidates,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                                if (hasSourceText) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.place_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          sourceText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF525A69),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (previewGroups.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6F7FB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: previewGroups
                                          .map(
                                            (group) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: _PreviewStatGroupRow(
                                                group: group,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ItemDescription(
                              itemName: widget.itemData['name'],
                              rarity: widget.itemData['rarity'],
                              slot: widget.itemData['slot'],
                              obtainedFrom: widget.obtainedFrom,
                              attributes: widget.itemData['attributes'],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class ItemCompleteFrame extends StatelessWidget {
  final String slot;
  final String rarity;
  /// Outer size in logical pixels (default matches item cards).
  final double size;
  /// Dark interior gradient for HUD-style panels (e.g. Builder).
  final bool darkInterior;
  /// Solo con [darkInterior]: ajusta el degradado (Humans / Tribes / Aliens).
  final BuilderHudInterior builderHudInterior;
  /// Si es false, solo se ve el marco y el fondo (sin icono del slot).
  final bool showInteriorIcon;

  const ItemCompleteFrame({
    super.key,
    required this.slot,
    required this.rarity,
    this.size = 62,
    this.darkInterior = false,
    this.builderHudInterior = BuilderHudInterior.human,
    this.showInteriorIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final String repo = slot.toUpperCase();
    final String iconPath = 'assets/generated/item_icons/named/icons/$repo.png';
    final String framePath =
        'assets/generated/item_icons/named/frames/${repo}_frame.png';
    final String overlayPath =
        'assets/generated/item_icons/named/overlays/${repo}_overlay.png';
    final Color highlightColor = getRarityHighlightColor(rarity);
    final double s = size;
    final double pad = s * 7 / 62;
    final double inner = s * 48 / 62;
    final double radius = s * 10 / 62;
    final int cache = (s * 2).round();

    return Container(
      width: s,
      height: s,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: darkInterior ? null : const Color(0xFFF7F7F9),
                gradient: darkInterior ? _darkHudGradient(builderHudInterior) : null,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          if (showInteriorIcon)
            Padding(
              padding: EdgeInsets.all(pad),
              child: Image.asset(
                iconPath,
                width: inner,
                height: inner,
                cacheWidth: cache,
                cacheHeight: cache,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.inventory_2_outlined,
                    size: inner * 0.58,
                    color: const Color(0xFF8F96A3),
                  );
                },
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                overlayPath,
                width: s,
                height: s,
                cacheWidth: cache,
                cacheHeight: cache,
                fit: BoxFit.contain,
                color: highlightColor,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                framePath,
                width: s,
                height: s,
                cacheWidth: cache,
                cacheHeight: cache,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isBright = color.computeLuminance() > 0.6;
    final textColor = Color.alphaBlend(
      Colors.black.withValues(alpha: isBright ? 0.72 : 0.6),
      color,
    );
    final iconColor = isBright
        ? Color.alphaBlend(
            Colors.black.withValues(alpha: 0.58),
            color,
          )
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isBright ? 0.055 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: isBright ? 0.1 : 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitInfoChip extends StatelessWidget {
  const _UnitInfoChip({
    required this.label,
    required this.color,
    required this.assetCandidates,
  });

  final String label;
  final Color color;
  final List<String> assetCandidates;

  @override
  Widget build(BuildContext context) {
    final isBright = color.computeLuminance() > 0.6;
    final textColor = Color.alphaBlend(
      Colors.black.withValues(alpha: isBright ? 0.72 : 0.6),
      color,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isBright ? 0.055 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: isBright ? 0.1 : 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResolvedMiniAssetImage(candidates: assetCandidates),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButtonChip extends StatelessWidget {
  const _IconButtonChip({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F3F7),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: const Color(0xFF5F6677)),
        ),
      ),
    );
  }
}

class _SelectActionChip extends StatelessWidget {
  const _SelectActionChip({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF667eea),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet body: same information as an expanded [ExpandableCard] (summary + optional [ItemDescription]).
class ItemCatalogDetailSheetBody extends StatefulWidget {
  const ItemCatalogDetailSheetBody({
    super.key,
    required this.name,
    required this.map,
    required this.rarity,
    required this.obtainedFrom,
    required this.itemData,
    this.onPrimaryAction,
    this.primaryActionLabel = 'Equip',
  });

  final String name;
  final String map;
  final String rarity;
  final String obtainedFrom;
  final Map<String, dynamic> itemData;
  final VoidCallback? onPrimaryAction;
  final String primaryActionLabel;

  @override
  State<ItemCatalogDetailSheetBody> createState() =>
      _ItemCatalogDetailSheetBodyState();
}

class _ItemCatalogDetailSheetBodyState extends State<ItemCatalogDetailSheetBody> {
  bool _ingamePreviewOpen = false;

  @override
  Widget build(BuildContext context) {
    final itemData = widget.itemData;
    final rarityColor = getRarityColor(itemData['rarity']);
    final readableAccent = _itemCatalogReadableAccent(rarityColor);
    final previewGroups = _itemCatalogPreviewGroups(itemData['attributes']);
    final affectedUnits = _itemCatalogAffectedUnits(itemData['attributes']);
    final sourceText = _itemCatalogSourceText(widget.map, itemData);
    final hasSourceText = sourceText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemCompleteFrame(
              slot: itemData['slot'],
              rarity: itemData['rarity'],
              size: 56,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      color: readableAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      height: 1.1,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (widget.onPrimaryAction != null) ...[
                    const SizedBox(height: 10),
                    _SelectActionChip(
                      label: widget.primaryActionLabel,
                      onPressed: widget.onPrimaryAction!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: rarityToString(widget.rarity),
                        color: rarityColor,
                        icon: Icons.stars_rounded,
                      ),
                      _InfoChip(
                        label: getSlotValueOrDescription(itemData['slot']),
                        color: const Color(0xFF5E6678),
                        icon: Icons.category_outlined,
                      ),
                    ],
                  ),
                  if (affectedUnits.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: affectedUnits
                          .map(
                            (unit) => _UnitInfoChip(
                              label: unit.label,
                              color: const Color(0xFF5E6678),
                              assetCandidates: unit.assetCandidates,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (hasSourceText) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sourceText,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF525A69),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (previewGroups.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: previewGroups
                            .map(
                              (group) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _PreviewStatGroupRow(group: group),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                setState(() => _ingamePreviewOpen = !_ingamePreviewOpen),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'In-game preview',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: readableAccent.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                  Icon(
                    _ingamePreviewOpen
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: const Color(0xFF64748B),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_ingamePreviewOpen) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(8),
            child: ItemDescription(
              itemName: itemData['name'] as String,
              rarity: itemData['rarity'] as String,
              slot: itemData['slot'] as String,
              obtainedFrom: widget.obtainedFrom,
              attributes: itemData['attributes'] as Map<String, dynamic>,
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewStatGroupRow extends StatelessWidget {
  const _PreviewStatGroupRow({
    required this.group,
  });

  final _PreviewStatGroup group;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 84),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            group.unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF566072),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: group.lines
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _PreviewStatLineRow(line: line),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PreviewStatLineRow extends StatelessWidget {
  const _PreviewStatLineRow({
    required this.line,
  });

  final _PreviewStatLine line;

  @override
  Widget build(BuildContext context) {
    final isNegative = line.amount.trim().startsWith('-');
    final amountColor =
        isNegative ? const Color(0xFFC75A5A) : const Color(0xFF2E9B62);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line.amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (line.attribute.isNotEmpty) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              line.attribute,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF3D4452),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewStatGroup {
  const _PreviewStatGroup({
    required this.unit,
    required this.lines,
  });

  final String unit;
  final List<_PreviewStatLine> lines;
}

class _AffectedUnitChipData {
  const _AffectedUnitChipData({
    required this.label,
    required this.assetCandidates,
  });

  final String label;
  final List<String> assetCandidates;
}

class _PreviewStatLine {
  const _PreviewStatLine({
    required this.amount,
    required this.attribute,
  });

  final String amount;
  final String attribute;
}

