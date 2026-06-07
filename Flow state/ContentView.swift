import SwiftUI

struct Task: Identifiable {
    let id = UUID()

    var name: String
    var dueDate: Date
    var duration: Int
}

struct ContentView: View {

    @State private var startTime = Date()
    @State private var endTime = Calendar.current.date(
        byAdding: .hour,
        value: 4,
        to: Date()
    ) ?? Date()

    @State private var newTask = ""
    @State private var dueDate = Date()
    @State private var durationText = "30"

    @State private var generatedFlow: [String] = []

    @State private var currentTask = "No task scheduled"

    @State private var tasks: [Task] = [
        Task(
            name: "Math Homework",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            duration: 60
        ),
        Task(
            name: "Study Biology",
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            duration: 45
        ),
        Task(
            name: "Clean Room",
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            duration: 30
        )
    ]

    var body: some View {
        NavigationView {

            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {

                    VStack(alignment: .leading, spacing: 16) {

                        Text("FlowState")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(Color.white)

                        // MARK: - TIME BLOCK
                        Text("Available Time")
                            .foregroundStyle(Color.white)
                            .font(.headline)

                        VStack(spacing: 10) {
                            DatePicker(
                                "Start Time",
                                selection: $startTime,
                                displayedComponents: .hourAndMinute
                            )
                            .colorScheme(.dark)

                            DatePicker(
                                "End Time",
                                selection: $endTime,
                                displayedComponents: .hourAndMinute
                            )
                            .colorScheme(.dark)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.gray.opacity(0.12))
                        )

                        Text("Available: \(availableMinutes()) min")
                            .foregroundStyle(.gray)

                        // MARK: - ADD TASK
                        Text("Add Task")
                            .foregroundStyle(Color.white)
                            .font(.headline)

                        VStack(spacing: 12) {

                            TextField("Task Name", text: $newTask)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.15))
                                )
                                .foregroundStyle(Color.white)

                            DatePicker(
                                "Due Date",
                                selection: $dueDate,
                                displayedComponents: .date
                            )
                            .colorScheme(.dark)

                            TextField("Duration (min)", text: $durationText)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: durationText) { newValue in
                                    durationText = newValue.filter { $0.isNumber }
                                }
                                .foregroundStyle(Color.white)

                            Button {
                                guard !newTask.isEmpty,
                                      let duration = Int(durationText) else { return }

                                tasks.append(
                                    Task(
                                        name: newTask,
                                        dueDate: dueDate,
                                        duration: duration
                                    )
                                )

                                newTask = ""
                                durationText = "30"

                            } label: {
                                Text("Add Task")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundStyle(Color.white)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.8))
                                    )
                            }
                        }

                        // MARK: - TASK LIST
                        Text("Tasks")
                            .foregroundStyle(Color.white)
                            .font(.headline)

                        ForEach(tasks) { task in

                            HStack {

                                VStack(alignment: .leading, spacing: 4) {

                                    Text(task.name)
                                        .foregroundStyle(Color.white)

                                    Text("Due: \(task.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)

                                    Text("\(task.duration) min")
                                        .foregroundStyle(Color.gray)
                                        .font(.caption)
                                }

                                Spacer()

                                Text(urgencyEmoji(task))
                                    .font(.title3)

                                Button {
                                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                                        tasks.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.gray.opacity(0.12))
                            )
                        }

                        // MARK: - GENERATE BUTTON
                        Button {
                            generatedFlow = generateFlow()
                        } label: {
                            Text("Generate Flow")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(Color.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.8))
                                )
                        }

                        // MARK: - OUTPUT
                        if !generatedFlow.isEmpty {

                            Text("Task For Now")
                                .foregroundStyle(Color.white)
                                .font(.headline)

                            Text(currentTask)
                                .foregroundStyle(Color.blue)
                                .bold()

                            Text("Generated Flow")
                                .foregroundStyle(Color.white)
                                .font(.headline)

                            ForEach(generatedFlow, id: \.self) { line in
                                Text(line)
                                    .foregroundStyle(Color.gray)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - LOGIC

    func availableMinutes() -> Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    func priorityScore(for task: Task) -> Double {
        let days = task.dueDate.timeIntervalSinceNow / 86400

        if days < 0 { return 100 }
        if days <= 1 { return 10 }
        if days <= 3 { return 8 }
        if days <= 7 { return 6 }
        if days <= 14 { return 4 }
        return 2
    }

    func score(for task: Task) -> Double {
        priorityScore(for: task) + Double(task.duration) / 60
    }

    func urgencyEmoji(_ task: Task) -> String {
        let days = task.dueDate.timeIntervalSinceNow / 86400

        if days <= 1 { return "🔴" }
        if days <= 7 { return "🟡" }
        return "🟢"
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func generateFlow() -> [String] {

        var result: [String] = []

        let sorted = tasks.sorted {
            score(for: $0) > score(for: $1)
        }

        var current = startTime

        for task in sorted {

            let end = Calendar.current.date(
                byAdding: .minute,
                value: task.duration,
                to: current
            ) ?? current

            if end > endTime { continue }

            result.append(
                "\(urgencyEmoji(task)) \(task.name) (\(formatTime(current)) - \(formatTime(end)))"
            )

            current = end
        }

        result.append("")
        result.append("____________________________")

        currentTask = sorted.first?.name ?? "No task scheduled"

        return result
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
