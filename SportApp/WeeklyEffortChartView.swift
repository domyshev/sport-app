import SwiftUI

struct WeeklyEffortChartView: View {
    let points: [WeeklyEffortPoint]
    @Binding var selectedPoint: WeeklyEffortPoint?

    private let accent = Color(red: 0.0, green: 0.45, blue: 0.92)
    private let chartHeight: CGFloat = 250
    private let pointSpacing: CGFloat = 34
    private let horizontalInset: CGFloat = 22
    private let topPadding: CGFloat = 52
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
                        chartCanvas(width: chartWidth(minimumWidth: proxy.size.width), height: proxy.size.height)
                            .frame(width: chartWidth(minimumWidth: proxy.size.width), height: proxy.size.height)
                    }
                }
                .frame(height: chartHeight)

                if let first = points.first, let last = points.last {
                    HStack {
                        Text(first.tooltipStart)
                        Spacer()
                        Text(last.tooltipEnd)
                    }
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var emptyChart: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.secondarySystemBackground))
            .frame(height: chartHeight)
            .overlay {
                Text("Нет данных")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
    }

    private func chartCanvas(width: CGFloat, height: CGFloat) -> some View {
        let positions = pointPositions(width: width, height: height)

        let canvas = ZStack(alignment: .topLeading) {
            gridLines(width: width, height: height)

            linePath(positions: positions)
                .stroke(accent, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))

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
        ZStack {
            Circle()
                .fill(accent)
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
        max(CGFloat(max(points.count - 1, 0)) * pointSpacing + horizontalInset * 2, minimumWidth)
    }

    private func pointPositions(width: CGFloat, height: CGFloat) -> [CGPoint] {
        let maxValue = max(points.map(\.value).max() ?? 1, 1)
        let drawableHeight = max(height - topPadding - bottomPadding, 1)

        return points.enumerated().map { index, point in
            let x = horizontalInset + CGFloat(index) * pointSpacing
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
            for fraction in [0.25, 0.5, 0.75] {
                let y = topPadding + (height - topPadding - bottomPadding) * fraction
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
        }
        .stroke(Color(.systemGray5), lineWidth: 1)
    }

    private func tooltip(for point: WeeklyEffortPoint) -> some View {
        VStack(spacing: 4) {
            Text("Неделя")
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
        .background(Color(.darkGray).opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
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
        selectedPoint: .constant(nil)
    )
    .padding()
}
