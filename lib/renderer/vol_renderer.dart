import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:k_chart/flutter_k_chart.dart';

class VolRenderer extends BaseChartRenderer<VolumeEntity> {
  late double mVolWidth;
  final ChartStyle chartStyle;
  final ChartColors chartColors;

  VolRenderer(Rect mainRect, double maxValue, double minValue,
      double topPadding, int fixedLength, this.chartStyle, this.chartColors)
      : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            fixedLength: fixedLength,
            gridColor: chartColors.gridColor) {
    mVolWidth = this.chartStyle.volWidth;
  }

  @override
  void drawChart(
      VolumeEntity lastPoint,
      VolumeEntity curPoint,
      double lastX,
      double curX,
      double middleX,
      double? ytdClosePrice,
      Size size,
      Canvas canvas) {
    double r = mVolWidth / 2;
    double top = getVolY(curPoint.vol);
    double bottom = chartRect.bottom;
    if (curPoint.vol != 0) {
      canvas.drawRect(Rect.fromLTRB(curX - r, top, curX + r, bottom),
          chartPaint..color = this.chartColors.volBarColor);
    }

    // if (lastPoint.MA5Volume != 0) {
    //   drawLine(lastPoint.MA5Volume, curPoint.MA5Volume, canvas, lastX, curX,
    //       this.chartColors.ma5Color);
    // }

    // if (lastPoint.MA10Volume != 0) {
    //   drawLine(lastPoint.MA10Volume, curPoint.MA10Volume, canvas, lastX, curX,
    //       this.chartColors.ma10Color);
    // }
  }

  double getVolY(double value) =>
      (maxValue - value) * (chartRect.height / maxValue) + chartRect.top;

  @override
  void drawText(Canvas canvas, VolumeEntity data, double x) {
    TextSpan span = TextSpan(
        text: "${NumberUtil.format(data.vol)}",
        style: getTextStyle(this.chartColors.defaultTextColor));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    double offsetX = chartRect.width - tp.width;
    Paint volPaint = new Paint()..color = this.chartColors.volBgColor;
    double top = getVolY(data.vol) - tp.width / 2;

    canvas.drawRect(
        Rect.fromLTRB(
            offsetX - 8, top - 3, offsetX + tp.width + 8, top + tp.height + 3),
        volPaint);
    tp.paint(canvas, Offset(offsetX, top));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    // TextSpan span =
    //     TextSpan(text: "${NumberUtil.format(maxValue)}", style: textStyle);
    // TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    // tp.layout();
    // tp.paint(
    //     canvas, Offset(chartRect.width - tp.width, chartRect.top - topPadding));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.bottom),
        Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //vol垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - topPadding),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}
