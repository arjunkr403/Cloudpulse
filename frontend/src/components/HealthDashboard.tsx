import React from "react";

import type { HealthData } from "../types";
interface HealthDashboardProps {
  healthData: HealthData | null;
}

const HealthDashboard: React.FC<HealthDashboardProps> = ({ healthData }) => {
  return (
    <section className="bg-white p-6 rounded-lg shadow-md">
      <h2 className="text-xl font-semibold mb-6 text-gray-800 flex items-center">
        <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
        System Health Monitor
      </h2>
      {healthData ? (
        <div>
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="p-4 bg-gray-50 rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
              <p className="text-xs text-gray-400 uppercase font-bold tracking-widest mb-1">
                Global Status
              </p>
              <p
                className={`text-2xl font-black ${healthData.status === "healthy" ? "text-emerald-500" : "text-amber-500"} capitalize`}
              >
                {healthData.status}
              </p>
            </div>
            {healthData.system && (
              <div className="p-4 bg-gray-50 rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
                <p className="text-xs text-gray-400 uppercase font-bold tracking-widest mb-1">
                  Resource Load
                </p>
                <div className="flex items-end gap-1">
                  <span className="text-2xl font-black text-gray-700">
                    {healthData.system.cpu}%
                  </span>
                  <span className="text-xs text-gray-400 pb-1">CPU</span>
                  <span className="mx-1 text-gray-300">|</span>
                  <span className="text-2xl font-black text-gray-700">
                    {healthData.system.memory}%
                  </span>
                  <span className="text-xs text-gray-400 pb-1">RAM</span>
                </div>
              </div>
            )}
          </div>
          <h3 className="text-sm font-bold text-gray-500 uppercase tracking-widest mb-4">
            Service Dependencies
          </h3>
          <ul className="space-y-3">
            {Object.entries(healthData.services || {}).map(
              ([service, status]) => (
                <li
                  key={service}
                  className="flex justify-between items-center p-4 bg-white rounded-xl border border-gray-50 shadow-sm hover:border-emerald-100 transition-colors"
                >
                  <span className="capitalize text-gray-600 font-semibold">
                    {service}
                  </span>
                  <span
                    className={`px-3 py-1 rounded-lg text-xs font-black uppercase tracking-tighter ${
                      status === "up"
                        ? "bg-emerald-100 text-emerald-700"
                        : "bg-rose-100 text-rose-700"
                    }`}
                  >
                    {status}
                  </span>
                </li>
              ),
            )}
          </ul>
        </div>
      ) : (
        <div className="animate-pulse space-y-4">
          <div className="h-24 bg-gray-100 rounded-xl"></div>
          <div className="h-48 bg-gray-100 rounded-xl"></div>
        </div>
      )}
    </section>
  );
};

export default HealthDashboard;
