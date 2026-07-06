import { Quaternion } from '@kit.ArkGraphics3D';

export class MathUtil {
  static readonly TWO_PI: number = Math.PI * 2;

  static aboutZ(angleRad: number): Quaternion {
    const half: number = angleRad * 0.5;
    return { x: 0, y: 0, z: Math.sin(half), w: Math.cos(half) } as Quaternion;
  }

  static fromTo(ax: number, ay: number, az: number,
    bx: number, by: number, bz: number): Quaternion {
    const dot: number = ax * bx + ay * by + az * bz;
    if (dot >= 0.999999) {
      return { x: 0, y: 0, z: 0, w: 1 } as Quaternion;
    }
    if (dot <= -0.999999) {
      let ox: number = 0;
      let oy: number = 0;
      if (Math.abs(ax) < 0.9) { ox = 1; } else { oy = 1; }
      const px: number = oy * az;
      const py: number = -ox * az;
      const pz: number = ox * ay - oy * ax;
      const pl: number = Math.sqrt(px * px + py * py + pz * pz) || 1;
      return { x: px / pl, y: py / pl, z: pz / pl, w: 0 } as Quaternion;
    }
    const cx: number = ay * bz - az * by;
    const cy: number = az * bx - ax * bz;
    const cz: number = ax * by - ay * bx;
    const w: number = 1 + dot;
    const l: number = Math.sqrt(cx * cx + cy * cy + cz * cz + w * w) || 1;
    return { x: cx / l, y: cy / l, z: cz / l, w: w / l } as Quaternion;
  }

  // Linear interpolation
  static lerp(a: number, b: number, t: number): number {
    return a + (b - a) * t;
  }

  // Length of a 3-vector
  static length3(x: number, y: number, z: number): number {
    return Math.sqrt(x * x + y * y + z * z);
  }
}