import { getDeviceInfo } from "@/renderer/services/FlowChartServices";
import { atom, useAtomValue, useSetAtom } from "jotai";
import { useCallback } from "react";
import { z } from "zod";

const CameraDevice = z.object({
  name: z.string(),
  id: z.union([z.string(), z.number()]),
});

type CameraDevice = z.infer<typeof CameraDevice>;

const SerialDevice = z.object({
  description: z.string(),
  hwid: z.string(),
  port: z.string(),
  manufacturer: z.nullable(z.string()),
});

type SerialDevice = z.infer<typeof SerialDevice>;

const VISADevice = z.object({
  name: z.string(),
  address: z.string(),
  description: z.string(),
});

type VISADevice = z.infer<typeof VISADevice>;

const NIDAQmxDevice = z.object({
  name: z.string(),
  address: z.string(),
  description: z.string(),
});

type NIDAQmxDevice = z.infer<typeof NIDAQmxDevice>;

const NIDMMDevice = z.object({
  name: z.string(),
  address: z.string(),
  description: z.string(),
});

type NIDMMDevice = z.infer<typeof NIDMMDevice>;

const DeviceInfo = z.object({
  cameras: z.array(CameraDevice),
  serialDevices: z.array(SerialDevice),
  visaDevices: z.array(VISADevice),
  nidaqmxDevices: z.array(NIDAQmxDevice),
  nidmmDevices: z.array(NIDMMDevice),
});

export type DeviceInfo = z.infer<typeof DeviceInfo>;

const deviceAtom = atom<DeviceInfo | undefined>(undefined);

const refetchDeviceInfo = async (
  discoverNIDAQmxDevices = false,
  discoverNIDMMDevices = false,
) => {
  const data = await getDeviceInfo(
    discoverNIDAQmxDevices,
    discoverNIDMMDevices,
  );
  return DeviceInfo.parse(data);
};

export const useHardwareRefetch = () => {
  const setDevices = useSetAtom(deviceAtom);

  return useCallback(
    async (discoverNIDAQmxDevices, discoverNIDMMDevices) => {
      setDevices(undefined);
      const data = await refetchDeviceInfo(
        discoverNIDAQmxDevices,
        discoverNIDMMDevices,
      );
      setDevices(data);
    },
    [setDevices],
  );
};

export const useHardwareDevices = () => useAtomValue(deviceAtom);
