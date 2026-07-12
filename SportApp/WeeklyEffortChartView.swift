import SwiftUI

struct WeeklyEffortChartView: View {
    let points: [WeeklyEffortPoint]
    @Binding var selectedPoint: WeeklyEffortPoint?
    let chartScale: WeeklyEffortChartScale

    private let palette = SportAppVisualStyle.palette
    private let chartHeight: CGFloat = 250
    private let horizontalInset: CGFloat = 22
    private let leadingAxisInset: CGFloat = 42
    private let topPadding: CGFloat = 22
    private let bottomPadding: CGFloat = 34
    private let pointDiameter: CGFloat = 3
    private let hitDiameter: CGFloat = 28
    private let tooltipWidth: CGFloat = 138
    private let interactionPolicy = WeeklyEffortChartInteractionPolicy.scrollFirst

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if points.isEmpty {
                emptyChart
            } else {
                GeometryReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        chartCanvas(
                            width: chartWidth(minimumWidth: proxy.size.width),
                            height: proxy.size.height,
                            visibleWidth: proxy.size.width
                        )
                            .frame(width: chartWidth(minimumWidth: proxy.size.width), height: proxy.size.height)
                    }
                }
                .frame(height: chartHeight)
                .background(Color(palette.panel).opacity(0.72), in: RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius)
                        .stroke(Color(palette.panelStroke), lineWidth: 1)
                }
                .shadow(color: Color(palette.electricCyan).opacity(palette.panelGlowOpacity), radius: 16, x: 0, y: 8)
            }
        }
    }

    private var emptyChart: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(palette.panel))
            .frame(height: chartHeight)
            .overlay {
                RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius)
                    .stroke(Color(palette.panelStroke), lineWidth: 1)
            }
            .overlay {
                Text("Нет данных")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(palette.secondaryText))
            }
    }

    private func chartCanvas(width: CGFloat, height: CGFloat, visibleWidth: CGFloat) -> some View {
        let positions = pointPositions(width: width, height: height)
        let xAxisLabels = WeeklyEffortChartAxisValues.xAxisLabels(
            for: points,
            visibleWidth: visibleWidth,
            pointSpacing: chartScale.pointSpacing
        )
        let yAxisLabels = WeeklyEffortChartAxisValues.yAxisLabels(maxValue: points.map(\.value).max() ?? 0)

        let canvas = ZStack(alignment: .topLeading) {
            gridLines(width: width, height: height)

            ForEach(Array(yAxisLabels.enumerated()), id: \.offset) { index, value in
                Text(axisValueText(value))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.tertiary)
                    .frame(width: leadingAxisInset - 6, alignment: .trailing)
                    .position(x: (leadingAxisInset - 6) / 2, y: yPosition(index: index, count: yAxisLabels.count, height: height))
            }

            ForEach(xAxisLabels, id: \.index) { label in
                Text(label.text)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.tertiary)
                    .fixedSize()
                    .position(x: positions[label.index].x, y: height - bottomPadding / 2)
            }

            linePath(positions: positions)
                .stroke(Color(palette.cyanGlow).opacity(palette.lineGlowOpacity), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .blur(radius: 6)

            linePath(positions: positions)
                .stroke(Color(palette.primaryText).opacity(0.9), style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))

            linePath(positions: positions)
                .stroke(Color(palette.electricCyan), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))

            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                pointHitArea(point: point)
                    .position(positions[index])
            }

            if let selectedPoint, let index = points.firstIndex(of: selectedPoint) {
                tooltip(for: selectedPoint)
                    .position(tooltipPosition(for: positions[index], width: width))
            }
        }

        return withCanvasDragSelection(canvas, positions: positions)
    }

    @ViewBuilder
    private func withCanvasDragSelection<Content: View>(
        _ content: Content,
        positions: [CGPoint]
    ) -> some View {
        if interactionPolicy.allowsCanvasDragSelection {
            content
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            selectedPoint = nearestPoint(to: value.location, positions: positions)
                        }
                )
        } else {
            content
        }
    }

    private func pointHitArea(point: WeeklyEffortPoint) -> some View {
        let isSelected = selectedPoint == point
        let pointColor = isSelected ? Color(palette.emberOrange) : Color(palette.electricCyan)

        return ZStack {
            Circle()
                .fill(pointColor.opacity(isSelected ? 0.38 : 0.22))
                .frame(width: isSelected ? 18 : 12, height: isSelected ? 18 : 12)
                .blur(radius: 3)
            Circle()
                .fill(Color(palette.primaryText))
                .frame(width: isSelected ? 8 : 6, height: isSelected ? 8 : 6)
            Circle()
                .fill(pointColor)
                .frame(width: pointDiameter, height: pointDiameter)
        }
        .frame(width: hitDiameter, height: hitDiameter)
        .contentShape(Circle())
        .onTapGesture {
            selectedPoint = point
        }
        .onHover { isHovered in
            if isHovered {
                selectedPoint = point
            } else if selectedPoint == point {
                selectedPoint = nil
            }
        }
    }

    private func chartWidth(minimumWidth: CGFloat) -> CGFloat {
        max(leadingAxisInset + CGFloat(max(points.count - 1, 0)) * chartScale.pointSpacing + horizontalInset * 2, minimumWidth)
    }

    private func pointPositions(width: CGFloat, height: CGFloat) -> [CGPoint] {
        let maxValue = max(points.map(\.value).max() ?? 0, 1)
        let drawableHeight = max(height - topPadding - bottomPadding, 1)

        return points.enumerated().map { index, point in
            let x = leadingAxisInset + horizontalInset + CGFloat(index) * chartScale.pointSpacing
            let normalizedValue = point.value / maxValue
            let y = topPadding + drawableHeight * (1 - normalizedValue)
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(positions: [CGPoint]) -> Path {
        Path { path in
            guard let first = positions.first else {
                return
            }

            path.move(to: first)
            for position in positions.dropFirst() {
                path.addLine(to: position)
            }
        }
    }

    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            for index in 0..<4 {
                let y = yPosition(index: index, count: 4, height: height)
                path.move(to: CGPoint(x: leadingAxisInset, y: y))
                path.addLine(to: CGPoint(x: width - horizontalInset, y: y))
            }
        }
        .stroke(Color(palette.panelStroke).opacity(0.42), lineWidth: 1)
    }

    private func yPosition(index: Int, count: Int, height: CGFloat) -> CGFloat {
        guard count > 1 else {
            return height - bottomPadding
        }

        let fraction = CGFloat(index) / CGFloat(count - 1)
        return height - bottomPadding - (height - topPadding - bottomPadding) * fraction
    }

    private func axisValueText(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    private func tooltip(for point: WeeklyEffortPoint) -> some View {
        VStack(spacing: 4) {
            Text(point.tooltipTitle)
                .font(.system(size: 12, weight: .bold))
            Text(point.tooltipStart)
                .font(.system(size: 12, weight: .regular))
            Text(point.tooltipEnd)
                .font(.system(size: 12, weight: .regular))
        }
        .frame(width: tooltipWidth)
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(.vertical, 8)
        .background(Color(palette.background).opacity(0.96), in: RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: SportAppVisualStyle.cardRadius)
                .stroke(Color(palette.emberOrange).opacity(0.7), lineWidth: 1)
        }
        .shadow(color: Color(palette.emberOrange).opacity(0.32), radius: 10, x: 0, y: 4)
    }

    private func tooltipPosition(for point: CGPoint, width: CGFloat) -> CGPoint {
        let halfTooltip = tooltipWidth / 2
        let x = min(max(point.x, halfTooltip), width - halfTooltip)
        let y = max(28, point.y - 36)
        return CGPoint(x: x, y: y)
    }

    private func nearestPoint(to location: CGPoint, positions: [CGPoint]) -> WeeklyEffortPoint? {
        guard let nearest = positions.enumerated().min(by: { lhs, rhs in
            abs(lhs.element.x - location.x) < abs(rhs.element.x - location.x)
        }) else {
            return nil
        }

        return points[nearest.offset]
    }
}

#Preview {
    WeeklyEffortChartView(
        points: [
            WeeklyEffortPoint(
                weekStart: Date(timeIntervalSince1970: 1_749_945_600),
                weekEnd: Date(timeIntervalSince1970: 1_750_464_000),
                value: 5
            ),
            WeeklyEffortPoint(
                weekStart: Date(timeIntervalSince1970: 1_750_550_400),
                weekEnd: Date(timeIntervalSince1970: 1_751_068_800),
                value: 11
            ),
            WeeklyEffortPoint(
                weekStart: Date(timeIntervalSince1970: 1_751_155_200),
                weekEnd: Date(timeIntervalSince1970: 1_751_673_600),
                value: 7
            )
        ],
        selectedPoint: .constant(nil),
        chartScale: .standard
    )
    .padding()
}
