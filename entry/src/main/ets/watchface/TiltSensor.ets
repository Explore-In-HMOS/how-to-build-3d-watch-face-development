import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MathUtil } from './MathUtil';

const ALPHA: number = 0.15;   // smoothing factor: lower = steadier but slower

export class TiltSensor {
  gx: number = 0;
  gy: number = 0;
  gz: number = 1;
  dirty: boolean = false;

  private started: boolean = false;

  start(): void {
    if (this.started) { return; }
    try {
      sensor.on(sensor.SensorId.GRAVITY, (data: sensor.GravityResponse): void => {
        this.onGravity(data.x, data.y, data.z);
      }, { interval: 50000000 }); // nanosecond
      this.started = true;
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`TiltSensor: subscribe failed code=${err.code} msg=${err.message}`);
    }
  }

  stop(): void {
    if (!this.started) { return; }
    try {
      sensor.off(sensor.SensorId.GRAVITY);
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      console.error(`TiltSensor: unsubscribe failed code=${err.code}`);
    }
    this.started = false;
  }

  private onGravity(x: number, y: number, z: number): void {
    const len: number = MathUtil.length3(x, y, z);
    if (len < 1e-4) { return; }
    this.gx = MathUtil.lerp(this.gx, x / len, ALPHA);
    this.gy = MathUtil.lerp(this.gy, y / len, ALPHA);
    this.gz = MathUtil.lerp(this.gz, z / len, ALPHA);
    this.dirty = true;
  }
}