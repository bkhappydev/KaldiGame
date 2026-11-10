import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/interfaces/topbar_clicklistener.dart';
import 'package:kaldi_app/utils/constant.dart';

/// Screen header: a 3D caramel ribbon with the title and, optionally, a 3D
/// back button. Music and settings live in the bottom navigation now.
class CommonTopBar extends StatelessWidget {
  final String headerName;
  final TopBarClickListener? clickListener;
  final bool isShowBack;

  const CommonTopBar(
    this.headerName,
    this.clickListener, {
    this.isShowBack = false,
    super.key,
  });

  static const double _buttonSize = 50;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        MediaQuery.paddingOf(context).top + 10,
        14,
        6,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _buttonSize,
            child: isShowBack
                ? Coffee3DIconButton(
                    semanticLabel:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    icon: Icons.arrow_back_rounded,
                    size: _buttonSize,
                    color: CoffeePalette.mocha,
                    onTap: () =>
                        clickListener?.onTopBarClick(Constant.strBack),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Semantics(header: true, child: _Title(headerName)),
            ),
          ),
          const SizedBox(width: 8),
          // Mirrors the back button so the title stays centred.
          const SizedBox(width: _buttonSize),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: CoffeePalette.mocha,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: CoffeePalette.crema, width: 3),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CoffeePalette.honey, CoffeePalette.cinnamon],
          ),
        ),
        child: AutoSizeText(
          text,
          maxLines: 1,
          minFontSize: 14,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kGameFont,
            fontFamilyFallback: const ['Menbere'],
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              for (final o in const [
                Offset(2, 2),
                Offset(-2, 2),
                Offset(2, -2),
                Offset(-2, -2),
                Offset(0, 3),
              ])
                Shadow(color: CoffeePalette.espresso, offset: o),
            ],
          ),
        ),
      ),
    );
  }
}
