import 'package:flutter/material.dart' show Color, Colors;

class ChartColors {
  List<Color> bgColor = [Color(0x00000000), Color(0x00000000)];

  Color kLineColor = Color(0xff4C86CD);
  Color lineFillColor = Color(0x554C86CD);
  Color lineFillInsideColor = Color(0x00000000);
  Color ma5Color = Color(0xffC9B885);
  Color ma10Color = Color(0xff6CB0A6);
  Color ma30Color = Color(0xff9979C6);
  Color upColor = Color(0xff4DAA90);
  Color dnColor = Color(0xffC15466);
  Color volBarColor = Color(0x1f000000);
  Color volColor = Color(0xff4729AE);
  Color volBgColor = Color(0xffEEEEEE);

  Color macdColor = Color(0xff4729AE);
  Color difColor = Color(0xffC9B885);
  Color deaColor = Color(0xff6CB0A6);

  Color kColor = Color(0xffC9B885);
  Color dColor = Color(0xff6CB0A6);
  Color jColor = Color(0xff9979C6);
  Color rsiColor = Color(0xffC9B885);

  Color defaultTextColor = Color(0xff000000);
  Color legendTextColor = Color(0x8A000000);
  Color black = Color(0xff000000);
  Color white = Color(0xffffffff);

  Color nowPriceUpColor = Color(0xff4DAA90);
  Color nowPriceDnColor = Color(0xffC15466);
  Color nowPriceTextColor = Color(0xffffffff);
  Color nowPriceBgColor = Color(0xFF2F8DFA);

  Color yesterdayPriceTextColor = Color(0xff000000);
  Color yesterdayPriceBgColor = Color(0xffbdbdbd);

  //深度颜色
  Color depthBuyColor = Colors.green;
  Color depthBuyColorLight = Colors.green.shade100;
  Color depthBuyColorMediumLight = Colors.green.shade200;
  Color depthSellColor = Colors.red;
  Color depthSellColorLight = Colors.red.shade100;
  Color depthSellColorMediumLight = Colors.red.shade200;
  Color depthRemainColor = Color(0xff9E9E9E);

  //选中后显示值边框颜色
  Color selectBorderColor = Color(0xFF303030);

  //选中后显示值背景的填充颜色
  Color selectFillColor = Color(0xFF303030);

  //分割线颜色
  Color gridColor = Color(0xff4c5c74);

  Color infoWindowNormalColor = Color(0xffffffff);
  Color infoWindowTitleColor = Color(0xffffffff);
  Color infoWindowUpColor = Color(0xff00ff00);
  Color infoWindowDnColor = Color(0xffff0000);

  Color hCrossColor = Color(0x00000000);
  Color vCrossColor = Color(0x00000000);
  Color crossTextColor = Color(0xffffffff);

  //当前显示内最大和最小值的颜色
  Color maxColor = Color(0xffffffff);
  Color minColor = Color(0xffffffff);

  // Buy, Sell, Dividend
  Color buy = Color(0xFF008750);
  Color sell = Color(0xFFFEB0E29);
  Color dividend = Color(0xFFBF31EA);

  Color getMAColor(int index) {
    switch (index % 3) {
      case 1:
        return ma10Color;
      case 2:
        return ma30Color;
      default:
        return ma5Color;
    }
  }
}

class ChartStyle {
  double topPadding = 30.0;

  double bottomPadding = 20.0;

  double childPadding = 12.0;

  //点与点的距离
  double pointWidth = 11.0;

  //蜡烛宽度
  double candleWidth = 8.5;

  //蜡烛中间线的宽度
  double candleLineWidth = 1.5;

  //vol柱子宽度
  double volWidth = 8.5;

  //macd柱子宽度
  double macdWidth = 3.0;

  //垂直交叉线宽度
  double vCrossWidth = 8.5;

  //水平交叉线宽度
  double hCrossWidth = 0.5;

  //现在价格的线条长度
  double nowPriceLineLength = 1;

  //现在价格的线条间隔
  double nowPriceLineSpan = 1;

  //现在价格的线条粗细
  double nowPriceLineWidth = 1;

  int gridRows = 4;

  int gridColumns = 4;

  //下方時間客製化
  List<String>? dateTimeFormat;

  List<String>? tooltipDateFormat;
}
