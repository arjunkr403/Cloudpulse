import { useState, useEffect } from "react";
import HealthDashboard from "./components/HealthDashboard";
import AlertHistory from "./components/AlertHistory";

function App() {
  const [healthData, setHealthData] = useState(null);
  const [alerts, setAlerts] = useState([]);

  const fetchHealth = async () => {
    try {
      const res = await fetch("/api/health");
      if (res.ok) {
        const data = await res.json();
        setHealthData(data.data || data);
      }
    } catch (e) {
      console.error("Failed to fetch health", e);
    }
  };

  const fetchAlerts = async () => {
    try {
      const res = await fetch("/api/alerts");
      if (res.ok) {
        const data = await res.json();
        setAlerts(data);
      }
    } catch (e) {
      console.error("Failed to fetch alerts", e);
    }
  };

  useEffect(() => {
    fetchHealth();
    fetchAlerts();
    const intervalId = setInterval(() => {
      fetchHealth();
      fetchAlerts();
    }, 5000);
    return () => clearInterval(intervalId);
  }, []);

  return (
    <div className="min-h-screen bg-slate-50 p-4 md:p-8">
      <header className="max-w-7xl mx-auto mb-10 flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <div className="bg-indigo-600 p-2 rounded-lg shadow-lg shadow-indigo-200">
              <svg
                className="w-6 h-6 text-white"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                />
              </svg>
            </div>
            <h1 className="text-4xl font-black text-slate-900 tracking-tight">
              CloudPulse
            </h1>
          </div>
          <p className="text-slate-500 font-medium ml-1">
            Observability & Self-Healing Command Center
          </p>
        </div>
        <div className="flex items-center gap-2 bg-white px-4 py-2 rounded-full shadow-sm border border-slate-100">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          <span className="text-xs font-bold text-slate-600 uppercase tracking-widest">
            Live Sync Active
          </span>
        </div>
      </header>

      <main className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-8">
        <div className="lg:col-span-5">
          <HealthDashboard healthData={healthData} />
        </div>
        <div className="lg:col-span-7">
          <AlertHistory alerts={alerts} />
        </div>
      </main>

      <footer className="max-w-7xl mx-auto mt-12 pt-8 border-t border-slate-200">
        <p className="text-center text-slate-400 text-xs font-medium uppercase tracking-[0.2em]">
          CloudPulse Engine v1.0 • Phase 1 Core
        </p>
      </footer>
    </div>
  );
}

export default App;
