import SwiftUI
import EventKit

struct CalendarEventView: View {
    let event: EKEvent
    @State private var showEventDetail = false
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let location = event.location {
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Событие")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.white)
                        
                        Text(eventTimeString)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .padding(.horizontal)
            .onTapGesture {
                showEventDetail.toggle()
            }
        }
    }
    
    private var eventTimeString: String {
        if event.isAllDay {
            return "Весь день"
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
        }
    }
}
