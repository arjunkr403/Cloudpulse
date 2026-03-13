import React, { useState } from "react";
import type { Alert } from "../types";

interface AlertHistoryProps {
  alerts: Alert[];
}

const AlertHistory: React.FC<AlertHistoryProps> = ({ alerts }) => {
  const [filterSeverity, setFilterSeverity] = useState<string>("all");

  const filteredAlerts = alerts.filter(
    (alert) => filterSeverity === "all" || alert.severity === filterSeverity,
  );

  return (
    <section className="bg-white p-6 rounded-lg shadow-md flex flex-col h-full">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-semibold text-gray-800 flex items-center">
          <span className="w-2 h-2 bg-rose-500 rounded-full mr-2"></span>
          Incident Log
        </h2>

        {/* Improved Dropdown Menu */}
        <div className="relative inline-block text-left">
          <select
            value={filterSeverity}
            onChange={(e) => setFilterSeverity(e.target.value)}
            className="appearance-none block w-full bg-gray-50 border border-gray-200 text-gray-700 py-2 px-4 pr-10 rounded-xl leading-tight focus:outline-none focus:bg-white focus:border-indigo-500 font-semibold text-sm transition-all duration-200 shadow-sm cursor-pointer"
          >
            <option value="all">All Incidents</option>
            <option value="info">Info Only</option>
            <option value="warning">Warning</option>
            <option value="critical">Critical</option>
          </select>
          <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3 text-gray-400">
            <svg
              className="fill-current h-4 w-4"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
            >
              <path d="M9.293 12.95l.707.707L15.657 8l-1.414-1.414L10 10.828 5.757 6.586 4.343 8z" />
            </svg>
          </div>
        </div>
      </div>

      <div
        className="overflow-y-auto flex-grow space-y-3 pr-1"
        style={{ maxHeight: "450px" }}
      >
        {filteredAlerts.length > 0 ? (
          filteredAlerts.map((alert) => (
            <div
              key={alert.id}
              className="p-4 bg-white border border-gray-100 rounded-xl shadow-sm hover:shadow-md transition-all group"
            >
              <div className="flex justify-between items-start mb-2">
                <span
                  className={`px-3 py-1 text-[10px] font-black uppercase tracking-widest rounded-lg ${
                    alert.severity === "critical"
                      ? "bg-rose-100 text-rose-700 border border-rose-200"
                      : alert.severity === "warning"
                        ? "bg-amber-100 text-amber-700 border border-amber-200"
                        : "bg-sky-100 text-sky-700 border border-sky-200"
                  }`}
                >
                  {alert.severity}
                </span>
                <span className="text-[11px] font-mono text-gray-400 group-hover:text-gray-600 transition-colors">
                  {new Date(alert.created_at).toLocaleTimeString([], {
                    hour: "2-digit",
                    minute: "2-digit",
                    second: "2-digit",
                  })}
                </span>
              </div>
              <h4 className="font-bold text-gray-800 text-sm">{alert.title}</h4>
              <p className="text-xs text-gray-500 mt-1 leading-relaxed">
                {alert.description}
              </p>
            </div>
          ))
        ) : (
          <div className="flex flex-col items-center justify-center py-20 text-gray-300">
            <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mb-4">
              <svg
                className="w-8 h-8"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <p className="text-sm font-semibold">No incidents found.</p>
          </div>
        )}
      </div>
    </section>
  );
};

export default AlertHistory;
