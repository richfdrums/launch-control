import SwiftUI

/// The 0–60 timer: arm, launch, and the time.
struct LaunchView: View {
    @Environment(RunController.self) private var run
    @Environment(History.self) private var history
    @Environment(\.palette) private var p
    @State private var showHistory = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                Button { showHistory = true } label: { Label("Runs", systemImage: "list.bullet") }
                    .buttonStyle(ThemedButtonStyle(prominent: false))
            }
            .padding(.horizontal)
            Spacer(minLength: 0)
            status
            readout.frame(maxHeight: 200).padding(.horizontal)
            Text("SECONDS").font(p.font(20)).tracking(6).foregroundStyle(p.dim)
            details.frame(minHeight: 90, alignment: .top)
            Spacer(minLength: 0)
            controls.padding(.bottom, 24)
        }
        .sheet(isPresented: $showHistory) { HistoryView().environment(\.palette, p) }
    }

    @ViewBuilder private var readout: some View {
        switch run.state {
        case .running(let start):
            TimelineView(.animation(minimumInterval: 0.01)) { timeline in
                Readout(text: seconds(timeline.date.timeIntervalSince1970 - start))
            }
        case .finished(let record, _):
            Readout(text: seconds(record.result.zeroToSixty))
        default:
            Readout(text: "0.00").opacity(run.state == .ready ? 1 : 0.5)
        }
    }

    @ViewBuilder private var status: some View {
        Group {
            switch run.state {
            case .idle:
                Text(history.best.map { "BEST \(seconds($0.result.zeroToSixty)) S" } ?? "STOP, THEN ARM")
            case .arming(let why):
                Text(why.uppercased())
            case .ready:
                Text("READY: LAUNCH WHEN YOU ARE")
                    .foregroundStyle(p.accent)
                    .phaseAnimator([0.35, 1.0]) { view, opacity in view.opacity(opacity) } animation: { _ in .easeInOut(duration: 0.7) }
            case .running:
                Text("\(Int((run.liveSpeed / Units.mph).rounded())) MPH")
            case .finished(_, let best):
                Text(best ? "NEW BEST" : "0–60 MPH").foregroundStyle(best ? p.accent : p.text)
            case .aborted(let why):
                Text(why.uppercased())
            }
        }
        .font(p.font(20))
        .tracking(2)
        .foregroundStyle(p.text)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }

    @ViewBuilder private var details: some View {
        if case .finished(let record, _) = run.state {
            VStack(spacing: 8) {
                detail("1-ft rollout", seconds(record.result.withRollout) + " s")
                detail("0–30", seconds(record.result.zeroToThirty) + " s")
                detail("Peak", String(format: "%.2f g", record.result.peakG))
            }
        }
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label.uppercased()).foregroundStyle(p.dim)
            Spacer()
            Text(value).foregroundStyle(p.text).monospacedDigit()
        }
        .font(p.font(17))
        .frame(maxWidth: 280)
    }

    @ViewBuilder private var controls: some View {
        switch run.state {
        case .idle, .aborted:
            Button("ARM") { run.arm() }.buttonStyle(ThemedButtonStyle())
        case .finished:
            Button("RUN AGAIN") { run.arm() }.buttonStyle(ThemedButtonStyle())
        default:
            Button("CANCEL") { run.cancel() }.buttonStyle(ThemedButtonStyle(prominent: false))
        }
    }
}

func seconds(_ t: Double) -> String { String(format: "%.2f", max(0, t)) }
