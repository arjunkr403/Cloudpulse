export interface Alert {
  id: number;
  title: string;
  description: string;
  severity: string;
  created_at: string;
}

export interface HealthData {
  status: string;
  timestamp: number;
  services: Record<string, string>;
  system?: {
    cpu: number;
    memory: number;
  };
}