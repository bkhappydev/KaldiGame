import 'package:flutter/material.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/commonTopBar/common_topbar.dart';
import 'package:kaldi_app/common/effects/bouncy_button.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/rewards/gift_box.dart';
import 'package:kaldi_app/rewards/reward_store.dart';
import 'package:kaldi_app/rewards/treats.dart';

/// "My Treats": waiting gifts to open, and the collection of won sweets.
class TreatsScreen extends StatelessWidget {
  const TreatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    final String code = Localizations.localeOf(context).languageCode;
    final RewardStore store = RewardStore.instance;

    return CoffeeBackdrop(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final int pending = store.pendingGifts;
          return CustomScrollView(
            slivers: [
              // The title scrolls away with the content.
              SliverToBoxAdapter(child: CommonTopBar(lang.txtMyTreats, null)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child:
                      pending > 0
                          ? _waitingGifts(context, lang, pending)
                          : _nextGiftHint(lang, store),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _TreatTile(
                      treat: Treats.all[i],
                      count: store.countOf(Treats.all[i]),
                      name: Treats.all[i].nameFor(code),
                    ),
                    childCount: Treats.all.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _waitingGifts(BuildContext context, Languages lang, int pending) {
    return Semantics(
      button: true,
      label: '${lang.txtGiftsWaiting(pending)} ${lang.txtTapToOpen}',
      excludeSemantics: true,
      onTap: () => openWaitingGifts(context),
      child: BouncyButton(
        onTap: () => openWaitingGifts(context),
        child: Coffee3DPanel(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            children: [
              WigglingGift(
                size: 130,
                colors:
                    Treats.wrapColors[RewardStore.instance.giftsOpened %
                        Treats.wrapColors.length],
              ),
              const SizedBox(height: 6),
              OutlinedGameText(
                lang.txtGiftsWaiting(pending),
                fontSize: 22,
                fill: CoffeePalette.gold,
              ),
              const SizedBox(height: 4),
              Pulse(
                child: Text(
                  lang.txtTapToOpen,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: CoffeePalette.cherry,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextGiftHint(Languages lang, RewardStore store) {
    final int need = RewardStore.starsPerGift - store.starsTowardNext;
    return Coffee3DPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: [
          Opacity(
            opacity: 0.85,
            child: GiftBox3D(
              size: 80,
              colors:
                  Treats.wrapColors[store.giftsOpened %
                      Treats.wrapColors.length],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.txtStarsToNextGift(need),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: CoffeePalette.roast,
                  ),
                ),
                const SizedBox(height: 8),
                StarMeter(
                  value: store.starsTowardNext,
                  max: RewardStore.starsPerGift,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreatTile extends StatelessWidget {
  final Treat treat;
  final int count;
  final String name;

  const _TreatTile({
    required this.treat,
    required this.count,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final bool locked = count == 0;
    // Read as one item: "Chocolate, 2" or "Locked".
    return Semantics(
      label: locked ? '?' : '$name, $count',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: CoffeePalette.cinnamon,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: CoffeePalette.caramel, width: 3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  locked
                      ? [CoffeePalette.mocha, CoffeePalette.roast]
                      : [CoffeePalette.foam, CoffeePalette.latte],
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder:
                            (context, box) => Treat3D(
                              treat: treat,
                              locked: locked,
                              size: box.maxHeight * 0.92,
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        locked ? '???' : name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color:
                              locked
                                  ? CoffeePalette.latte
                                  : CoffeePalette.roast,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CoffeePalette.cherry,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '×$count',
                      style: const TextStyle(
                        fontFamily: kGameFont,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of [max] stars with the first [value] filled, as a 3D meter.
class StarMeter extends StatelessWidget {
  final int value;
  final int max;
  final double size;

  const StarMeter({
    super.key,
    required this.value,
    required this.max,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CoffeePalette.roast,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: CoffeePalette.caramel, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(max, (i) {
          final bool on = i < value;
          return Icon(
            Icons.star_rounded,
            size: size,
            color: on ? CoffeePalette.gold : CoffeePalette.mocha,
            shadows:
                on
                    ? const [
                      Shadow(
                        color: CoffeePalette.cinnamon,
                        offset: Offset(0, 2),
                      ),
                    ]
                    : null,
          );
        }),
      ),
    );
  }
}
