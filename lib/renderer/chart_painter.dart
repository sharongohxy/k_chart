import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';
import 'package:k_chart/entity/chart_fixed_dot_entity.dart';
import 'package:k_chart/utils/number_util.dart';

import '../entity/info_window_entity.dart';
import '../entity/k_line_entity.dart';
import '../utils/date_format_util.dart';
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine
  final bool isTrendLine; //For TrendLine
  bool isrecordingCord = false; //For TrendLine
  final double selectY; //For TrendLine
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer, mSecondaryRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  Color? upColor, dnColor;
  Color? ma5Color, ma10Color, ma30Color;
  Color? volColor;
  Color? macdColor, difColor, deaColor, jColor;
  int fixedLength;
  List<int> maDayList;
  final ChartColors chartColors;
  late Paint selectPointPaint,
      selectorBorderPaint,
      nowPricePaint,
      yesterdayLastPricePaint;
  final ChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final VerticalTextAlignment verticalTextAlignment;
  final bool showYesterdayLastPriceLine;
  final double? yesterdayLastPrice;
  final bool coloriseChartBasedOnBaselineValue;
  final bool? isSparklineChart;
  final bool? forceShowBeginningOfXAxis;
  final bool? showNeutralColorWhenLivePriceIsSameAsYesterdayClosePrice;
  final double? valueToCompareToColoriseChart;
  final bool? showCrossLineVolume;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines, //For TrendLine
    required this.isTrendLine, //For TrendLine
    required this.selectY, //For TrendLine
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required xFrontPadding,
    isOnTap,
    isTapShowInfoDialog,
    required this.verticalTextAlignment,
    mainState,
    volHidden,
    secondaryState,
    this.sink,
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.fixedLength = 4,
    this.maDayList = const [5, 10, 20],
    this.showYesterdayLastPriceLine = true,
    this.yesterdayLastPrice,
    this.coloriseChartBasedOnBaselineValue = false,
    this.isSparklineChart = false,
    this.forceShowBeginningOfXAxis = true,
    this.showNeutralColorWhenLivePriceIsSameAsYesterdayClosePrice = true,
    this.valueToCompareToColoriseChart,
    this.showCrossLineVolume = true,
  }) : super(
          chartStyle,
          datas: datas,
          scaleX: scaleX,
          scrollX: scrollX,
          isLongPress: isLongPass,
          isOnTap: isOnTap,
          isTapShowInfoDialog: isTapShowInfoDialog,
          selectX: selectX,
          mainState: mainState,
          volHidden: volHidden,
          secondaryState: secondaryState,
          xFrontPadding: xFrontPadding,
          isLine: isLine,
          showYesterdayLastPriceLine: showYesterdayLastPriceLine,
          yesterdayLastPrice: yesterdayLastPrice,
          forceShowBeginningOfXAxis: forceShowBeginningOfXAxis,
        ) {
    selectPointPaint = Paint()
      // ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = this.chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = this.chartColors.selectBorderColor;
    nowPricePaint = Paint()
      ..strokeWidth = this.chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
    yesterdayLastPricePaint = Paint()
      ..strokeWidth = this.chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    if (datas != null && datas!.isNotEmpty) {
      var t = datas![0];
    }

    double mLineStrokeWidth = (isSparklineChart ?? false) ? 0.8 : 2.0;
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainState,
      isLine,
      fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      verticalTextAlignment,
      showYesterdayLastPriceLine,
      yesterdayLastPrice,
      coloriseChartBasedOnBaselineValue,
      datas,
      showNeutralColorWhenLivePriceIsSameAsYesterdayClosePrice,
      maDayList,
      mLineStrokeWidth,
    );
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(mVolRect!, mVolMaxValue, mVolMinValue,
          mChildPadding, fixedLength, this.chartStyle, this.chartColors);
    }
    // if (mSecondaryRect != null) {
    //   mSecondaryRenderer = SecondaryRenderer(
    //       mSecondaryRect!,
    //       mSecondaryMaxValue,
    //       mSecondaryMinValue,
    //       mChildPadding,
    //       secondaryState,
    //       fixedLength,
    //       chartStyle,
    //       chartColors);
    // }
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    Paint mBgPaint = Paint();
    Gradient mBgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: chartColors.bgColor,
    );

    Rect mainRect =
        Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + mTopPadding);
    canvas.drawRect(
        mainRect, mBgPaint..shader = mBgGradient.createShader(mainRect));

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(
          0, mVolRect!.top - mChildPadding, mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(
          volRect, mBgPaint..shader = mBgGradient.createShader(volRect));
    }

    if (mSecondaryRect != null) {
      Rect secondaryRect = Rect.fromLTRB(0, mSecondaryRect!.top - mChildPadding,
          mSecondaryRect!.width, mSecondaryRect!.bottom);
      canvas.drawRect(secondaryRect,
          mBgPaint..shader = mBgGradient.createShader(secondaryRect));
    }
    Rect dateRect =
        Rect.fromLTRB(0, size.height - mBottomPadding, size.width, size.height);
    canvas.drawRect(
        dateRect, mBgPaint..shader = mBgGradient.createShader(dateRect));
  }

  @override
  void drawGrid(canvas) {
    if (!hideGrid) {
      // mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      // mSecondaryRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    double value = hasYesterdayLastPrice() ? yesterdayLastPrice! : 0.0;
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KLineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);
      double middleX;

      if (hasYesterdayLastPrice()) {
        double priceDiffIndex = ((value - (curPoint.close ?? 0)).abs() -
                ((curPoint.close ?? 0) - (lastPoint.close ?? 0)).abs())
            .abs();
        middleX = (i - priceDiffIndex) * mPointWidth + mPointWidth / 2;
      } else {
        middleX = (getX(i) + getX(i + 1)) / 2;
      }

      mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, middleX, value,
          valueToCompareToColoriseChart, size, canvas);
      if (isSparklineChart == false) {
        mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, middleX,
            value, valueToCompareToColoriseChart, size, canvas);
      }
      // mSecondaryRenderer?.drawChart(
      //     lastPoint, curPoint, lastX, curX, size, canvas);

      ChartFixedDotEntity? chartFixedDotEntity = curPoint.chartFixedDot;
      if (chartFixedDotEntity != null) {
        DateTime curPointDateTime =
            DateTime.fromMillisecondsSinceEpoch(curPoint.time ?? 0);
        int curPointMillis = DateTime(curPointDateTime.year,
                curPointDateTime.month, curPointDateTime.day)
            .millisecondsSinceEpoch;
        if (chartFixedDotEntity.millisecond == curPointMillis) {
          double y = getMainY(curPoint.close ?? 0);
          drawDot(canvas, size, curX, y, chartFixedDotEntity);
        }
      }
    }

    if ((isLongPress == true || (isTapShowInfoDialog && isOnTap))) {
      drawCrossLine(canvas, size);
    }
    // if (isTrendLine == true) drawTrendLines(canvas, size);
    canvas.restore();
  }

  @override
  void drawVerticalText(Canvas canvas, Size size) {
    if (isSparklineChart == true) return;

    // Paint verticalBg = Paint()
    //   ..color = Colors.white
    //   ..strokeWidth = 1
    //   ..isAntiAlias = true;
    // canvas.drawRect(Rect.fromLTRB(250, 0, size.width, size.height), verticalBg);
    var textStyle = getTextStyle(this.chartColors.defaultTextColor);
    mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);
    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    // mSecondaryRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (isSparklineChart == true) return;
    if (datas == null) return;

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double x = 0.0;
    double y = 0.0;
    for (var i = 0; i <= mGridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);

        if (datas?[index] == null) continue;
        TextPainter tp = getTextPainter(getDate(datas![index].time), null);
        y = size.height - (mBottomPadding - tp.height) / 2 - tp.height;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x, y));
      }
    }

//    double translateX = xToTranslateX(0);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStartIndex].id));
//      tp.paint(canvas, Offset(0, y));
//    }
//    translateX = xToTranslateX(size.width);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStopIndex].id));
//      tp.paint(canvas, Offset(size.width - tp.width, y));
//    }
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    if (isSparklineChart == true) return;
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    TextSpan span = TextSpan(
      children: [
        TextSpan(
          text: "Price: ${point.close?.toStringAsFixed(fixedLength) ?? ''}  ",
          style: getTextStyle(
            this.chartColors.legendTextColor,
            fontSize: 12,
          ),
        ),
        if (showCrossLineVolume == true) ...[
          TextSpan(
            text:
                "Volume: ${formatAmountWithCommas(point.vol.toStringAsFixed(0))}",
            style: getTextStyle(
              this.chartColors.legendTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );

    TextPainter legendTp =
        TextPainter(text: span, textDirection: TextDirection.ltr);
    legendTp.layout();
    legendTp.paint(canvas, Offset(0, 0));

    double currentPrice = mMainMinValue +
        (mMainMaxValue - mMainMinValue) * (size.height - 0.16) / size.height;

    TextPainter tp = getTextPainter(
        point.close?.toStringAsFixed(fixedLength), chartColors.crossTextColor);
    double textHeight = tp.height;
    double textWidth = tp.width;
    double offsetX = mWidth - tp.width;
    double y = getMainY(point.close ?? 0);
    double top = y - tp.height / 2;

    canvas.drawRect(
        Rect.fromLTRB(
            offsetX - 8, top - 3, offsetX + tp.width + 8, top + tp.height + 3),
        selectPointPaint);
    tp.paint(canvas, Offset(offsetX, top));

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double x;
    TextPainter dateTp =
        getTextPainter(getTooltipDate(point.time), chartColors.crossTextColor);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - mBottomPadding;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //长按显示这条数据详情
    sink?.add(InfoWindowEntity(point));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    if (isSparklineChart == true) return;

    //长按显示按中的数据
    if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //松开显示最后一条数据
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    // mSecondaryRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    //绘制最大值和最小值
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
          "── " + mMainLowMinValue.toStringAsFixed(fixedLength),
          chartColors.minColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          mMainLowMinValue.toStringAsFixed(fixedLength) + " ──",
          chartColors.minColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
          "── " + mMainHighMaxValue.toStringAsFixed(fixedLength),
          chartColors.maxColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          mMainHighMaxValue.toStringAsFixed(fixedLength) + " ──",
          chartColors.maxColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (isSparklineChart == true) return;

    if (!this.showNowPrice) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = datas!.last.close ?? 0;
    double y = getMainY(value);

    //视图展示区域边界值绘制
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    nowPricePaint..color = this.chartColors.nowPriceBgColor;
    //先画横线

    //再画背景和文本
    TextPainter tp = getTextPainter(
      value.toStringAsFixed(fixedLength),
      this.chartColors.nowPriceTextColor,
    );
    double startX = 0;
    final max = mWidth - tp.width;
    final space = 2;
    while (startX < max) {
      canvas.drawLine(
          Offset(startX, y), Offset(startX + space, y), nowPricePaint);
      startX += space + space;
    }
    double offsetX;
    switch (verticalTextAlignment) {
      case VerticalTextAlignment.left:
        offsetX = 0;
        break;
      case VerticalTextAlignment.right:
        offsetX = mWidth - tp.width;
        break;
    }

    double top = y - tp.height / 2;
    canvas.drawRect(
        Rect.fromLTRB(
            offsetX - 8, top - 3, offsetX + tp.width + 8, top + tp.height + 3),
        nowPricePaint);
    tp.paint(canvas, Offset(offsetX, top));
  }

  @override
  void drawYesterdayLastPrice(Canvas canvas) {
    if (!this.showYesterdayLastPriceLine) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = yesterdayLastPrice!;
    double y = getMainY(value);

    //视图展示区域边界值绘制
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    yesterdayLastPricePaint..color = this.chartColors.yesterdayPriceBgColor;
    //先画横线

    //再画背景和文本
    TextPainter tp = getTextPainter(value.toStringAsFixed(fixedLength),
        this.chartColors.yesterdayPriceTextColor);
    double startX = 0;
    final max = mWidth - tp.width;
    final space = 2;
    while (startX < max) {
      canvas.drawLine(Offset(startX, y), Offset(startX + space, y),
          yesterdayLastPricePaint);
      startX += space + space;
    }
    double offsetX;
    switch (verticalTextAlignment) {
      case VerticalTextAlignment.left:
        offsetX = 0;
        break;
      case VerticalTextAlignment.right:
        offsetX = mWidth - tp.width;
        break;
    }

    if (isSparklineChart == false) {
      double top = y - tp.height / 2;
      canvas.drawRect(
          Rect.fromLTRB(offsetX - 8, top - 3, offsetX + tp.width + 8,
              top + tp.height + 3),
          yesterdayLastPricePaint);
      tp.paint(canvas, Offset(offsetX, top));
    }
  }

  @override
  void drawDot(Canvas canvas, Size size, double x, double y,
      ChartFixedDotEntity chartFixedDotEntity) {
    Paint dotBg = Paint()
      ..color = this.chartColors.white
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint dotValue = Paint()
      ..color = chartFixedDotEntity.color ?? this.chartColors.depthSellColor
      ..strokeWidth = 1
      ..isAntiAlias = true;
    canvas.drawCircle(
      Offset(x, y),
      chartFixedDotEntity.backgroundPointRadius ?? 7.0,
      dotBg,
    );
    canvas.drawCircle(
      Offset(x, y),
      chartFixedDotEntity.foregroundPointRadius ?? 5.5,
      dotValue,
    );
  }

  //For TrendLine
  void drawTrendLines(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    Paint paintY = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..isAntiAlias = true;
    double x = getX(index);
    trendLineX = x;

    double y = selectY;
    // getMainY(point.close);

    // k线图竖线
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);
    Paint paintX = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintY);
    // if (scaleX >= 1) {
    //   canvas.drawOval(
    //       Rect.fromCenter(
    //           center: Offset(x, y), height: 15.0 * scaleX, width: 15.0),
    //       paint);
    // } else {
    //   canvas.drawOval(
    //       Rect.fromCenter(
    //           center: Offset(x, y), height: 10.0, width: 10.0 / scaleX),
    //       paint);
    // }
    if (lines.length >= 1) {
      lines.forEach((element) {
        var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        var p1 = Offset(element.p1.dx, a);
        var p2 = Offset(element.p2.dx, b);
        // canvas.drawLine(
        //     p1,
        //     element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
        //     Paint()
        //       ..color = Colors.yellow
        //       ..strokeWidth = 2);
      });
    }
  }

  ///画交叉线
  void drawCrossLine(Canvas canvas, Size size) {
    if (isSparklineChart == true) return;

    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint dotClosePriceBg = Paint()
      ..color = this.chartColors.nowPriceBgColor
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint yesterdayClosePriceBg = Paint()
      ..color = this.chartColors.yesterdayPriceBgColor
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint dotBg = Paint()
      ..color = this.chartColors.white
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint paintLine = Paint()
      ..color = this.chartColors.black
      ..strokeWidth = this.chartStyle.hCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close ?? 0);
    double yClose =
        this.hasYesterdayLastPrice() ? getMainY(yesterdayLastPrice!) : 0.0;
    double nowPrice = this.showNowPrice && (datas?.isNotEmpty ?? false)
        ? getMainY(datas!.last.close ?? 0)
        : 0.0;
    // k线图竖线

    double dashHeight = 7, dashWidth = 7, dashSpace = 6;
    double startY = 20;
    while (startY < size.height - 20) {
      canvas.drawLine(
          Offset(x, startY), Offset(x, startY + dashHeight), paintLine);
      startY += dashHeight + dashSpace;
    }
    // k线图横线
    double start = -mTranslateX;
    final max = mWidth - 50;
    final dspace = 5;
    // double startX = -mTranslateX;
    // print(startX);
    // print(startX + mWidth / scaleX);
    // final max = -mTranslateX;
    // final space = 3;
    // while (startX < max) {
    //   canvas.drawLine(
    //       Offset(startX, y), Offset(startX + space, y), nowPricePaint);
    //   startX += space + space;
    // }
    // while (startX < max) {
    //   canvas.drawLine(Offset(startX, y), Offset(startX + space, y), paintX);
    //   startX += 10;
    // }
    while (start < max) {
      canvas.drawLine(
          Offset(start, y), Offset(start + dashWidth, y), paintLine);
      start += dashWidth + dashSpace;
    }
    // canvas.drawLine(
    //     Offset(startX, y), Offset(startX + mWidth / scaleX, y), paintX);
    double value = valueToCompareToColoriseChart != null
        ? valueToCompareToColoriseChart!
        : this.hasYesterdayLastPrice()
            ? yesterdayLastPrice!
            : 0.0;
    Paint paintDotBuySell = Paint()
      ..color = coloriseChartBasedOnBaselineValue
          ? ((point.close ?? 0) > value)
              ? this.chartColors.depthBuyColor
              : this.chartColors.depthSellColor
          : (datas!.last.close ?? 0) > value
              ? this.chartColors.depthBuyColor
              : this.chartColors.depthSellColor
      ..strokeWidth = 1
      ..isAntiAlias = true;
    if (this.hasYesterdayLastPrice()) {
      canvas.drawCircle(Offset(x, yClose), 5.5, dotBg);
      canvas.drawCircle(Offset(x, yClose), 4, yesterdayClosePriceBg);
    }
    if (this.showNowPrice) {
      canvas.drawCircle(Offset(x, nowPrice), 5.5, dotBg);
      canvas.drawCircle(Offset(x, nowPrice), 4, dotClosePriceBg);
    }
    canvas.drawCircle(Offset(x, y), 5.5, dotBg);
    canvas.drawCircle(Offset(x, y), 4, paintDotBuySell);
    // if (scaleX >= 1) {
    //   // canvas.drawOval(
    //   //     Rect.fromCenter(
    //   //         center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
    //   //     paintX);
    // } else {
    //   canvas.drawOval(
    //       Rect.fromCenter(
    //           center: Offset(x, y), height: 2.0, width: 2.0 / scaleX),
    //       paintX);
    // }
  }

  TextPainter getTextPainter(text, color) {
    if (color == null) {
      color = this.chartColors.defaultTextColor;
    }
    TextSpan span;
    if (isSparklineChart == true) {
      span = TextSpan(text: "", style: getTextStyle(color));
    } else {
      span = TextSpan(text: "$text", style: getTextStyle(color));
    }
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String formatAmountWithCommas(String num) {
    String numInText = "";
    int counter = 0;
    for (int i = (num.length - 1); i >= 0; i--) {
      counter++;
      String str = num[i];
      if ((counter % 3) != 0 && i != 0) {
        numInText = "$str$numInText";
      } else if (i == 0) {
        numInText = "$str$numInText";
      } else {
        numInText = ",$str$numInText";
      }
    }
    return numInText.trim();
  }

  String getDate(int? date) => dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      mFormats);

  String getTooltipDate(int? date) {
    return dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      tooltipDateFormats,
    );
  }

  double getMainY(double y) => mMainRenderer.getY(y);

  /// 点是否在SecondaryRect中
  bool isInSecondaryRect(Offset point) {
    return mSecondaryRect?.contains(point) ?? false;
  }

  /// 点是否在MainRect中
  bool isInMainRect(Offset point) {
    return mMainRect.contains(point);
  }
}
