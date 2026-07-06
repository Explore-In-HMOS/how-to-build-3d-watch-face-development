import {
  Scene,
  SceneResourceFactory,
  SceneNodeParameters,
  Light,
  LightType,
  DirectionalLight,
  Color,
  Quaternion
} from '@kit.ArkGraphics3D';
import { MathUtil } from './MathUtil';

const SHADOWS: boolean = true;

export class Lighting {
  key: DirectionalLight | null = null;
  fill: DirectionalLight | null = null;
  readonly fillBase: Quaternion = {
    x: 0,
    y: 0,
    z: 0,
    w: 1
  } as Quaternion;
  private factory: SceneResourceFactory;

  constructor(scene: Scene) {
    this.factory = scene.getResourceFactory();
  }

  async build(): Promise<void> {
    const fillParams: SceneNodeParameters = { name: 'fillLight', path: '/fillLight' };
    const fillBase: Light = await this.factory.createLight(fillParams, LightType.DIRECTIONAL);
    this.fill = fillBase as DirectionalLight;
    this.fill.color = {
      r: 1,
      g: 0,
      b: 0,
      a: 0.5
    } as Color;
    this.fill.intensity = 30;
    this.fill.shadowEnabled = false;
    this.fill.enabled = true;
    this.fill.rotation = this.fillBase;

    if (SHADOWS) {
      const keyParams: SceneNodeParameters = { name: 'sunLight', path: '/sunLight' };
      const keyBase: Light = await this.factory.createLight(keyParams, LightType.DIRECTIONAL);
      this.key = keyBase as DirectionalLight;
      this.key.color = {
        r: 1,
        g: 0.98,
        b: 0.94,
        a: 1
      } as Color;
      this.key.intensity = 15;
      this.key.shadowEnabled = true;
      this.key.enabled = true;
      this.key.rotation = this.fillBase;
    }
  }

  applySun(gx: number, gy: number, gz: number): void {
    if (!this.key) {
      return;
    }
    const fx: number = -gx;
    const fy: number = -gy;
    const fz: number = -gz;
    const l: number = MathUtil.length3(fx, fy, fz) || 1;
    this.key.rotation = MathUtil.fromTo(0, 0, -1, fx / l, fy / l, fz / l);
  }

  setAmbientMode(ambient: boolean): void {
    if (this.fill) {
      this.fill.enabled = true;
    }
    if (this.key) {
      this.key.shadowEnabled = !ambient;
    }
  }
}