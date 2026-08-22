pragma Singleton
import QtQuick
import Quickshell
import qs.src.services.system

Singleton {
    id: root

    // CPU
    readonly property real cpuUsage: CpuStats.usage
    readonly property var  cpuCores: CpuStats.cores
    readonly property real cpuFrequencyGhz: CpuStats.frequencyGhz

    // Memory
    readonly property real memUsage: MemoryStats.usage
    readonly property real memUsedGb: MemoryStats.usedGb
    readonly property real memTotalGb: MemoryStats.totalGb
    readonly property real memAvailableGb: MemoryStats.availableGb
    readonly property real swapUsage: MemoryStats.swapUsage
    readonly property real swapUsedGb: MemoryStats.swapUsedGb
    readonly property real swapTotalGb: MemoryStats.swapTotalGb

    // GPU
    readonly property real gpuUsage: GpuStats.usage
    readonly property bool hasGpu: GpuStats.available
    readonly property string gpuName: GpuStats.name
    readonly property real gpuVramUsedGb: GpuStats.vramUsedGb
    readonly property real gpuVramTotalGb: GpuStats.vramTotalGb
    readonly property int gpuTemperature: GpuStats.temperature

    // Disk
    readonly property var diskPartitions: DiskStats.partitions

    // Network
    readonly property string activeInterface: NetworkStats.activeInterface
    readonly property real netUpRate: NetworkStats.upRate
    readonly property real netDownRate: NetworkStats.downRate
    readonly property var netUpHistory: NetworkStats.upHistory
    readonly property var netDownHistory: NetworkStats.downHistory

    // Temperature
    readonly property var temperatures: ThermalStats.temperatures
    readonly property var displayTemperatures: ThermalStats.displayTemperatures
    readonly property int temperature: ThermalStats.primaryTemperature

    function formatBytes(bytes) {
        if (bytes >= 1e9) return (bytes / 1e9).toFixed(1) + " GB/s"
        if (bytes >= 1e6) return (bytes / 1e6).toFixed(1) + " MB/s"
        if (bytes >= 1e3) return (bytes / 1e3).toFixed(1) + " KB/s"
        return bytes.toFixed(0) + " B/s"
    }
}
