import { Scene, Camera, SceneNodeParameters, Color, Vec3 } from '@kit.ArkGraphics3D';
import { MathUtil } from './MathUtil';
import { Lighting } from './Lighting';
import { SceneGraph } from './SceneGraph';
import { TiltSensor } from './TiltSensor';

const FPS_ACTIVE: number = 30;
const FPS_AMBIENT: number = 1;

export class WatchFaceEngine {
  scene: Scene | null = null;

  private camera: Camera | null = null;
  private lighting: Lighting | null = null;
  private graph: SceneGraph | null = null;
  private sensor: TiltSensor = new TiltSensor();

  private timerId: number = -1;
  private ambient: boolean = false;

  async init(): Promise<Scene> {
    const result: Scene | undefined = await Scene.load();
    if (!result) {
      throw new Error('Scene.load() returned no scene');
    }
    const scene: Scene = result;
    this.scene = scene;

    await this.buildCamera();
    this.lighting = new Lighting(scene);
    await this.lighting.build();
    this.graph = new SceneGraph(scene);
    await this.graph.build();

    this.sensor.start();
    this.startTicker(FPS_ACTIVE);
    return scene;
  }

  private async buildCamera(): Promise<void> {
    if (!this.scene) { return; }
    const params: SceneNodeParameters = { name: 'camera' };
    const cam: Camera = await this.scene.getResourceFactory().createCamera(params);
    cam.position = { x: 0, y: 0, z: 6 } as Vec3;
    cam.fov = 0.55;
    cam.nearPlane = 0.5;
    cam.farPlane = 100;
    cam.clearColor = { r: 0.05, g: 0.06, b: 0.08, a: 1 } as Color;
    cam.enabled = true;
    this.camera = cam;
  }


  private startTicker(fps: number): void {
    this.stopTicker();
    const periodMs: number = Math.round(1000 / fps);
    this.timerId = setInterval((): void => { this.tick(); }, periodMs);
  }

  private stopTicker(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

private tick(): void {
  if (!this.scene || !this.graph) { return; }

  const nowMs: number = Date.now() / 1000;

  const sec: number = nowMs % 60;
  const min: number = (nowMs / 60) % 60;
  const hour: number = (nowMs / 3600) % 24;

  const msPart: number = (nowMs - Math.floor(nowMs)) * 1000;

  const secFrac: number = this.ambient ? sec : (sec + msPart / 1000);

  const thetaS: number = (secFrac / 60) * MathUtil.TWO_PI;
  const thetaM: number = ((min + sec / 60) / 60) * MathUtil.TWO_PI;
  const thetaH: number = (((hour % 12) + min / 60) / 12) * MathUtil.TWO_PI;

  if (this.graph.hourPivot) {
    this.graph.hourPivot.rotation = MathUtil.aboutZ(-thetaH);
  }
  if (this.graph.minutePivot) {
    this.graph.minutePivot.rotation = MathUtil.aboutZ(-thetaM);
  }
  if (this.graph.secondPivot) {
    this.graph.secondPivot.rotation = MathUtil.aboutZ(-thetaS);
  }

  if (this.lighting && this.sensor.dirty) {
    this.lighting.applySun(this.sensor.gx, this.sensor.gy, this.sensor.gz);
    this.sensor.dirty = false;
  }

  this.scene.renderFrame({ alwaysRender: false });
}

  setAmbientMode(ambient: boolean): void {
    if (this.ambient === ambient) { return; }
    this.ambient = ambient;
    if (this.lighting) { this.lighting.setAmbientMode(ambient); }
    this.startTicker(ambient ? FPS_AMBIENT : FPS_ACTIVE);
  }

  suspend(): void {
    this.stopTicker();
    this.sensor.stop();
  }

  resume(): void {
    this.sensor.start();
    this.startTicker(this.ambient ? FPS_AMBIENT : FPS_ACTIVE);
  }

  destroy(): void {
    this.stopTicker();
    this.sensor.stop();
    if (this.scene) {
      this.scene.destroy();
    }
    this.scene = null;
    this.camera = null;
    this.lighting = null;
    this.graph = null;
  }
}