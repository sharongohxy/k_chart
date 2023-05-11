import 'package:flutter/material.dart';
import 'package:k_chart/entity/k_line_entity.dart';

import '../entity/candle_entity.dart';
import '../k_chart_widget.dart' show MainState;
import 'base_chart_renderer.dart';

enum VerticalTextAlignment { left, right }

//For TrendLine
double? trendLineMax;
double? trendLineScale;
double? trendLineContentRec;

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  late double mCandleWidth;
  late double mCandleLineWidth;
  MainState state;
  bool isLine;

  //绘制的内容区域
  late Rect _contentRect;
  double _contentPadding = 5.0;
  List<int> maDayList;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final double mLineStrokeWidth;
  double scaleX;
  late Paint mLinePaint;
  final VerticalTextAlignment verticalTextAlignment;
  final bool showYesterdayLastPriceLine;
  final double? yesterdayLastPrice;
  final bool coloriseChartBasedOnBaselineValue;
  final List<KLineEntity>? datas;

  MainRenderer(
    Rect mainRect,
    double maxValue,
    double minValue,
    double topPadding,
    this.state,
    this.isLine,
    int fixedLength,
    this.chartStyle,
    this.chartColors,
    this.scaleX,
    this.verticalTextAlignment,
    this.showYesterdayLastPriceLine,
    this.yesterdayLastPrice,
    this.coloriseChartBasedOnBaselineValue,
    this.datas, [
    this.maDayList = const [5, 10, 20],
    this.mLineStrokeWidth = 2.0,
  ]) : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            fixedLength: fixedLength,
            gridColor: chartColors.gridColor) {
    mCandleWidth = this.chartStyle.candleWidth;
    mCandleLineWidth = this.chartStyle.candleLineWidth;
    mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = mLineStrokeWidth
      ..color = (datas?.length != 0 && yesterdayLastPrice != null)
          ? getKLineColor((datas!.last.close - yesterdayLastPrice!))
          : this.chartColors.depthRemainColor;
    // ..color = this.chartColors.kLineColor;
    _contentRect = Rect.fromLTRB(
        chartRect.left,
        chartRect.top + _contentPadding,
        chartRect.right,
        chartRect.bottom - _contentPadding);
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    scaleY = _contentRect.height / (maxValue - minValue);
  }

  createNewChartPoints() {
    if (datas == [])
      return;
    else {}
  }

  Color getKLineColor(num priceDifference) {
    if (priceDifference == 0)
      return chartColors.depthRemainColor;
    else if (priceDifference.isNegative)
      return chartColors.depthSellColor;
    else if (!(priceDifference.isNegative)) return chartColors.depthBuyColor;
    return chartColors.depthRemainColor;
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine == true) return;
    TextSpan? span;
    if (state == MainState.MA) {
      span = TextSpan(
        children: _createMATextSpan(data),
      );
    } else if (state == MainState.BOLL) {
      span = TextSpan(
        children: [
          if (data.up != 0)
            TextSpan(
                text: "BOLL:${format(data.mb)}    ",
                style: getTextStyle(this.chartColors.ma5Color)),
          if (data.mb != 0)
            TextSpan(
                text: "UB:${format(data.up)}    ",
                style: getTextStyle(this.chartColors.ma10Color)),
          if (data.dn != 0)
            TextSpan(
                text: "LB:${format(data.dn)}    ",
                style: getTextStyle(this.chartColors.ma30Color)),
        ],
      );
    }
    if (span == null) return;
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  List<InlineSpan> _createMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    for (int i = 0; i < (data.maValueList?.length ?? 0); i++) {
      if (data.maValueList?[i] != 0) {
        var item = TextSpan(
            text: "MA${maDayList[i]}:${format(data.maValueList![i])}    ",
            style: getTextStyle(this.chartColors.getMAColor(i)));
        result.add(item);
      }
    }
    return result;
  }

  @override
  void drawChart(
      CandleEntity lastPoint,
      CandleEntity curPoint,
      double lastX,
      double curX,
      double middleX,
      double? ytdClosePrice,
      Size size,
      Canvas canvas) {
    if (isLine) {
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX,
          middleX, ytdClosePrice);
    } else {
      drawCandle(curPoint, canvas, curX);
      if (state == MainState.MA) {
        drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
      } else if (state == MainState.BOLL) {
        drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
      }
    }
  }

  Shader? mLineFillShader, mRedLineFillShader, mGreenLineFillShader;
  Path? mLinePath,
      mLineFillPath,
      mGreenPartLinePath,
      mRedPartLinePath,
      mRedLineFillPath,
      mGreenLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
  Paint mRedLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
  Paint mGreenLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  //画折线图
  drawPolyline(double lastPrice, double curPrice, Canvas canvas, double lastX,
      double curX, double middleX, double? ytdClosePrice) {
//    drawLine(lastPrice + 100, curPrice + 100, canvas, lastX, curX, ChartColors.kLineColor);
    mLinePath = Path();
    mGreenPartLinePath = Path();
    mRedPartLinePath = Path();

//    if (lastX == curX) {
//      mLinePath.moveTo(lastX, getY(lastPrice));
//    } else {
////      mLinePath.lineTo(curX, getY(curPrice));
//      mLinePath.cubicTo(
//          (lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
//    }
    if (lastX == curX) lastX = 0; //起点位置填充

    if (coloriseChartBasedOnBaselineValue) {
      mLinePath!.moveTo(lastX, getY(lastPrice));
      if (ytdClosePrice != null) {
        if (curPrice < ytdClosePrice && lastPrice > ytdClosePrice) {
          mRedPartLinePath!.moveTo(curX, getY(curPrice));
          mGreenPartLinePath!.moveTo((curX + lastX) / 2, getY(ytdClosePrice));
          mRedPartLinePath!.lineTo((curX + lastX) / 2, getY(ytdClosePrice));
          mGreenPartLinePath!.lineTo(lastX, getY(lastPrice));

          // mRedPartLinePath!.cubicTo((lastX + curX) / 2, getY(ytdClosePrice),
          //     (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
          // mGreenPartLinePath!.cubicTo(
          //     (lastX + curX) / 2,
          //     getY(lastPrice),
          //     (lastX + curX) / 2,
          //     getY(ytdClosePrice),
          //     middleX,
          //     getY(ytdClosePrice));
        } else if (curPrice > ytdClosePrice && lastPrice < ytdClosePrice) {
          mGreenPartLinePath!.moveTo(curX, getY(curPrice));
          mRedPartLinePath!.moveTo((curX + lastX) / 2, getY(ytdClosePrice));
          mGreenPartLinePath!.lineTo((curX + lastX) / 2, getY(ytdClosePrice));
          mRedPartLinePath!.lineTo(lastX, getY(lastPrice));

          // mGreenPartLinePath!.moveTo((curX + lastX) / 2, getY(ytdClosePrice));
          // mRedPartLinePath!.moveTo(lastX, getY(lastPrice));
          // mGreenPartLinePath!.cubicTo((lastX + curX) / 2, getY(ytdClosePrice),
          //     (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
          // mRedPartLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
          //     (lastX + curX) / 2, getY(ytdClosePrice), curX, getY(ytdClosePrice));
        } else if (curPrice == ytdClosePrice || lastPrice == ytdClosePrice) {
          if (curPrice > ytdClosePrice && lastPrice == ytdClosePrice ||
              lastPrice > ytdClosePrice && curPrice == ytdClosePrice) {
            mGreenPartLinePath!.moveTo(curX, getY(curPrice));
            mGreenPartLinePath!.lineTo(lastX, getY(lastPrice));

            // mGreenPartLinePath!.moveTo(lastX, getY(lastPrice));
            // mGreenPartLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
            //     (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
          } else if (lastPrice < ytdClosePrice && curPrice == ytdClosePrice ||
              curPrice < ytdClosePrice && lastPrice == ytdClosePrice) {
            mRedPartLinePath!.moveTo(curX, getY(curPrice));
            mRedPartLinePath!.lineTo(lastX, getY(lastPrice));

            // mRedPartLinePath!.moveTo(lastX, getY(lastPrice));
            // mRedPartLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
            //     (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
          }
        } else {
          mLinePath!.moveTo(curX, getY(curPrice));
          mLinePath!.lineTo(lastX, getY(lastPrice));
        }
      }
    } else {
      mLinePath!.moveTo(lastX, getY(lastPrice));
      mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
          (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    }

    //画阴影
    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      tileMode: TileMode.clamp,
      colors: (lastPrice > ytdClosePrice! && curPrice > ytdClosePrice)
          ? [this.chartColors.depthBuyColor, this.chartColors.depthBuyColor]
          : [this.chartColors.depthSellColor, this.chartColors.depthSellColor],
      // tileMode: TileMode.mirror,
      // colors: [this.chartColors.lineFillColor, this.chartColors.lineFillColor],
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint..shader = mLineFillShader;

    mRedLineFillShader ??= LinearGradient(
      begin: coloriseChartBasedOnBaselineValue
          ? Alignment.bottomCenter
          : Alignment.topCenter,
      end: coloriseChartBasedOnBaselineValue
          ? Alignment.topCenter
          : Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [
        this.chartColors.depthSellColor.withOpacity(0.3),
        this.chartColors.depthSellColor.withOpacity(0.15),
        this.chartColors.depthSellColor.withOpacity(0.0),
      ],
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mRedLineFillPaint..shader = mRedLineFillShader;

    mGreenLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [
        this.chartColors.depthBuyColor.withOpacity(0.3),
        this.chartColors.depthBuyColor.withOpacity(0.15),
        this.chartColors.depthBuyColor.withOpacity(0.0),
      ],
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mGreenLineFillPaint..shader = mGreenLineFillShader;

    mLineFillPath ??= Path();
    mRedLineFillPath ??= Path();
    mGreenLineFillPath ??= Path();

    if (coloriseChartBasedOnBaselineValue) {
      if (ytdClosePrice != null) {
        if (curPrice < ytdClosePrice && lastPrice > ytdClosePrice) {
          mRedLineFillPath!.moveTo(curX, getY(ytdClosePrice));
          mGreenLineFillPath!.moveTo((curX + lastX) / 2, getY(ytdClosePrice));
          mRedLineFillPath!.lineTo(curX, getY(curPrice));
          mRedLineFillPath!.lineTo((curX + lastX) / 2, getY(ytdClosePrice));
          mRedLineFillPath!.close();

          mGreenLineFillPath!.lineTo(lastX, getY(ytdClosePrice));
          mGreenLineFillPath!.lineTo(lastX, getY(lastPrice));
          mGreenLineFillPath!.close();

          canvas.drawPath(mRedLineFillPath!, mRedLineFillPaint);
          canvas.drawPath(mGreenLineFillPath!, mGreenLineFillPaint);
          mRedLineFillPath!.reset();
          mGreenLineFillPath!.reset();
        } else if (curPrice > ytdClosePrice && lastPrice < ytdClosePrice) {
          mGreenLineFillPath!.moveTo(curX, getY(ytdClosePrice));
          mRedLineFillPath!.moveTo((curX + lastX) / 2, getY(ytdClosePrice));
          mGreenLineFillPath!.lineTo(curX, getY(curPrice));
          mGreenLineFillPath!.lineTo((curX + lastX) / 2, getY(ytdClosePrice));
          mGreenLineFillPath!.close();

          mRedLineFillPath!.lineTo(lastX, getY(ytdClosePrice));
          mRedLineFillPath!.lineTo(lastX, getY(lastPrice));
          mRedLineFillPath!.close();

          canvas.drawPath(mRedLineFillPath!, mRedLineFillPaint);
          canvas.drawPath(mGreenLineFillPath!, mGreenLineFillPaint);
          mRedLineFillPath!.reset();
          mGreenLineFillPath!.reset();
        } else if (curPrice == ytdClosePrice || lastPrice == ytdClosePrice) {
          if (curPrice > ytdClosePrice && lastPrice == ytdClosePrice ||
              lastPrice > ytdClosePrice && curPrice == ytdClosePrice) {
            mGreenLineFillPath!.moveTo(curX, getY(ytdClosePrice));
            if (curPrice > ytdClosePrice) {
              mGreenLineFillPath!.lineTo(curX, getY(curPrice));
              mGreenLineFillPath!.lineTo(lastX, getY(ytdClosePrice));
            } else if (lastPrice > ytdClosePrice) {
              mGreenLineFillPath!.lineTo(lastX, getY(ytdClosePrice));
              mGreenLineFillPath!.lineTo(lastX, getY(lastPrice));
            }
            mGreenLineFillPath!.close();

            canvas.drawPath(mGreenLineFillPath!, mGreenLineFillPaint);
            mGreenLineFillPath!.reset();
          } else if (lastPrice < ytdClosePrice && curPrice == ytdClosePrice ||
              curPrice < ytdClosePrice && lastPrice == ytdClosePrice) {
            mRedLineFillPath!.moveTo(curX, getY(ytdClosePrice));
            if (lastPrice < ytdClosePrice) {
              mRedLineFillPath!.lineTo(lastX, getY(ytdClosePrice));
              mRedLineFillPath!.lineTo(lastX, getY(lastPrice));
            } else if (curPrice < ytdClosePrice) {
              mRedLineFillPath!.lineTo(curX, getY(curPrice));
              mRedLineFillPath!.lineTo(lastX, getY(ytdClosePrice));
            }
            mRedLineFillPath!.close();
            canvas.drawPath(mRedLineFillPath!, mRedLineFillPaint);
            mRedLineFillPath!.reset();
          }
        } else {
          mLineFillPath!.moveTo(lastX, getY(ytdClosePrice));
          mLineFillPath!.lineTo(lastX, getY(lastPrice));

          mLineFillPath!.lineTo(curX, getY(curPrice));
          mLineFillPath!.lineTo(curX, getY(ytdClosePrice));
          mLineFillPath!.close();

          canvas.drawPath(
              mLineFillPath!,
              (lastPrice > ytdClosePrice && curPrice > ytdClosePrice)
                  ? mGreenLineFillPaint
                  : mRedLineFillPaint);
          mLineFillPath!.reset();
        }
      }
    } else {
      mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
      mLineFillPath!.lineTo(lastX, getY(lastPrice));
      mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
          (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
      mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
      mLineFillPath!.close();

      double latestClosePrice = datas!.last.close;

      if (ytdClosePrice != null) {
        canvas.drawPath(
            mLineFillPath!,
            latestClosePrice > ytdClosePrice
                ? mGreenLineFillPaint
                : mRedLineFillPaint);
        mLineFillPath!.reset();
      }

      if (ytdClosePrice != null) {
        canvas.drawPath(
            mLinePath!,
            mLinePaint
              ..strokeWidth = mLineStrokeWidth
              ..color = latestClosePrice > ytdClosePrice
                  ? chartColors.depthBuyColor
                  : chartColors.depthSellColor);
        mLinePath!.reset();
      }
    }

    if (curPrice < ytdClosePrice! && lastPrice > ytdClosePrice ||
        curPrice > ytdClosePrice && lastPrice < ytdClosePrice ||
        curPrice == ytdClosePrice ||
        lastPrice == ytdClosePrice) {
      canvas.drawPath(
          mRedPartLinePath!,
          mLinePaint
            ..strokeWidth = mLineStrokeWidth
            ..color = chartColors.depthSellColor);
      canvas.drawPath(
          mGreenPartLinePath!,
          mLinePaint
            ..strokeWidth = mLineStrokeWidth
            ..color = chartColors.depthBuyColor);
      mRedPartLinePath!.reset();
      mGreenPartLinePath!.reset();
    } else {
      canvas.drawPath(
          mLinePath!,
          mLinePaint
            ..strokeWidth = mLineStrokeWidth
            ..color = (lastPrice > ytdClosePrice && curPrice > ytdClosePrice)
                ? chartColors.depthBuyColor
                : chartColors.depthSellColor);
      mLinePath!.reset();
    }
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    for (int i = 0; i < (curPoint.maValueList?.length ?? 0); i++) {
      if (i == 3) {
        break;
      }
      if (lastPoint.maValueList?[i] != 0) {
        drawLine(lastPoint.maValueList?[i], curPoint.maValueList?[i], canvas,
            lastX, curX, this.chartColors.getMAColor(i));
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint,
      Canvas canvas, double lastX, double curX) {
    if (lastPoint.up != 0) {
      drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX,
          this.chartColors.ma10Color);
    }
    if (lastPoint.mb != 0) {
      drawLine(lastPoint.mb, curPoint.mb, canvas, lastX, curX,
          this.chartColors.ma5Color);
    }
    if (lastPoint.dn != 0) {
      drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX,
          this.chartColors.ma30Color);
    }
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = mCandleWidth / 2;
    double lineR = mCandleLineWidth / 2;
    if (open >= close) {
      // 实体高度>= CandleLineWidth
      if (open - close < mCandleLineWidth) {
        open = close + mCandleLineWidth;
      }
      chartPaint.color = this.chartColors.upColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else if (close > open) {
      // 实体高度>= CandleLineWidth
      if (close - open < mCandleLineWidth) {
        open = close - mCandleLineWidth;
      }
      chartPaint.color = this.chartColors.dnColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      double value = (gridRows - i) * rowSpace / scaleY + minValue;
      TextSpan span = TextSpan(text: "${format(value)}", style: textStyle);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      double offsetX;
      switch (verticalTextAlignment) {
        case VerticalTextAlignment.left:
          offsetX = 0;
          break;
        case VerticalTextAlignment.right:
          offsetX = chartRect.width - tp.width;
          break;
      }

      if (i == 0) {
        tp.paint(canvas, Offset(offsetX, topPadding));
      } else {
        tp.paint(
            canvas, Offset(offsetX, rowSpace * i - tp.height + topPadding));
      }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
//    final int gridRows = 4, gridColumns = 4;
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + topPadding),
          Offset(chartRect.width, rowSpace * i + topPadding), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, topPadding / 3),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  double getY(double y) {
    //For TrendLine
    updateTrendLineData();
    return (maxValue - y) * scaleY + _contentRect.top;
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
