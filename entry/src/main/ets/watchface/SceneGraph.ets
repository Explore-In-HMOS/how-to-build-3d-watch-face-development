import {
  Scene, SceneResourceFactory, SceneNodeParameters, Node, Geometry, MeshResource,
  CustomGeometry, PrimitiveTopology, Material, Color,
  Vec3, Vec2
} from '@kit.ArkGraphics3D';
import { Materials, Finishes } from './Materials';
import { MathUtil } from './MathUtil';

const USE_MATERIALS: boolean = false;

const Z_BACKDROP: number = -0.5;
const Z_DIAL: number = 0.0;
const Z_INDEX: number = 0.04;
const Z_HOUR: number = 0.10;
const Z_MIN: number = 0.16;
const Z_SEC: number = 0.22;
const Z_CAP: number = 0.30;

const C_CASE: Color = { r: 0.72, g: 0.53, b: 0.22, a: 1 } as Color;
const C_DIAL: Color = { r: 0.04, g: 0.24, b: 0.12, a: 1 } as Color;
const C_MARKER: Color = { r: 0.96, g: 0.80, b: 0.42, a: 1 } as Color;
const C_HAND: Color = { r: 0.96, g: 0.80, b: 0.42, a: 1 } as Color;
const C_SECOND: Color = { r: 0.99, g: 0.86, b: 0.54, a: 1 } as Color;

export class SceneGraph {
  watchRoot: Node | null = null;
  hourPivot: Node | null = null;
  minutePivot: Node | null = null;
  secondPivot: Node | null = null;

  private scene: Scene;
  private factory: SceneResourceFactory;
  private materials: Materials;

  constructor(scene: Scene) {
    this.scene = scene;
    this.factory = scene.getResourceFactory();
    this.materials = new Materials(scene);
  }

  async build(): Promise<void> {
    const rootParams: SceneNodeParameters = { name: 'watchRoot' };
    this.watchRoot = await this.factory.createNode(rootParams);

    await this.buildBackdrop();
    await this.buildDial();
    await this.buildIndices();
    await this.buildHands();
    await this.buildCap();
  }

  private async buildBackdrop(): Promise<void> {
    const disc: CustomGeometry = SceneGraph.makeDisc(3.0, 48, C_CASE);
    const mesh: MeshResource = await this.factory.createMesh({ name: 'backdropMesh' }, disc);
    const plate: Geometry = await this.factory.createGeometry({ name: 'backdrop' }, mesh);
    plate.position = { x: 0, y: 0, z: Z_BACKDROP } as Vec3;
    this.appendToRoot(plate);
  }

  private async buildDial(): Promise<void> {
    const disc: CustomGeometry = SceneGraph.makeDisc(1.7, 72, C_DIAL);
    const mesh: MeshResource = await this.factory.createMesh({ name: 'dialMesh' }, disc);
    const dial: Geometry = await this.factory.createGeometry({ name: 'dial' }, mesh);
    dial.position = { x: 0, y: 0, z: Z_DIAL } as Vec3;
    if (USE_MATERIALS) {
      dial.mesh.materialOverride = await this.materials.create('dialMat', Finishes.silverDial());
    }
    this.appendToRoot(dial);
  }

  private async buildIndices(): Promise<void> {
    const indexPivot: Node = await this.factory.createNode({ name: 'indexPivot' });
    this.appendToRoot(indexPivot);
    const radius: number = 1.42;

    let goldMat: Material | null = null;
    if (USE_MATERIALS) {
      goldMat = await this.materials.create('indexMat', Finishes.roseGold());
    }

    const TWO_PI = MathUtil.TWO_PI;

    for (let i = 0; i < 12; i++) {
      const angle: number = (i / 12) * TWO_PI;
      const isQuarter: boolean = (i % 3) === 0;
      const w: number = isQuarter ? 0.08 : 0.05;
      const h: number = isQuarter ? 0.22 : 0.16;
      const box: CustomGeometry = SceneGraph.makeBox(w, h, 0.04, C_MARKER);
      const m: MeshResource = await this.factory.createMesh({ name: `idxMesh_${i}` }, box);
      const g: Geometry = await this.factory.createGeometry({ name: `index_${i}` }, m);
      g.position = {
        x: Math.sin(angle) * radius,
        y: Math.cos(angle) * radius,
        z: Z_INDEX
      } as Vec3;
      g.rotation = MathUtil.aboutZ(-angle);
      if (goldMat) { g.mesh.materialOverride = goldMat; }
      indexPivot.children.append(g);
    }
  }

  private async buildHands(): Promise<void> {
    this.hourPivot = await this.factory.createNode({ name: 'hourPivot' });
    this.appendToRoot(this.hourPivot);
    const hour: Geometry = await this.makeBaton('hourHand', 0.09, 0.80, 0.04, Z_HOUR, C_HAND);
    this.hourPivot.children.append(hour);

    this.minutePivot = await this.factory.createNode({ name: 'minutePivot' });
    this.appendToRoot(this.minutePivot);
    const minute: Geometry =
      await this.makeBaton('minuteHand', 0.055, 1.30, 0.04, Z_MIN, C_HAND);
    this.minutePivot.children.append(minute);

    this.secondPivot = await this.factory.createNode({ name: 'secondPivot' });
    this.appendToRoot(this.secondPivot);
    const second: Geometry =
      await this.makeBaton('secondHand', 0.020, 1.45, 0.03, Z_SEC, C_SECOND);
    this.secondPivot.children.append(second);
    const tail: Geometry =
      await this.makeBatonOffset('secondTail', 0.04, 0.35, 0.03, Z_SEC, -0.175, C_SECOND);
    this.secondPivot.children.append(tail);
  }

  private async buildCap(): Promise<void> {
    const box: CustomGeometry = SceneGraph.makeBox(0.07, 0.07, 0.05, C_MARKER);
    const mesh: MeshResource = await this.factory.createMesh({ name: 'capMesh' }, box);
    const cap: Geometry = await this.factory.createGeometry({ name: 'capScrew' }, mesh);
    cap.position = { x: 0, y: 0, z: Z_CAP } as Vec3;
    if (USE_MATERIALS) {
      cap.mesh.materialOverride = await this.materials.create('capMat', Finishes.roseGold());
    }
    this.appendToRoot(cap);
  }

  private makeBaton(name: string, w: number, len: number, d: number, z: number,
    color: Color): Promise<Geometry> {
    return this.makeBatonOffset(name, w, len, d, z, len * 0.5, color);
  }

  private async makeBatonOffset(name: string, w: number, len: number, d: number, z: number,
    centreY: number, color: Color): Promise<Geometry> {
    const box: CustomGeometry = SceneGraph.makeBox(w, len, d, color);
    const mesh: MeshResource = await this.factory.createMesh({ name: `${name}Mesh` }, box);
    const g: Geometry = await this.factory.createGeometry({ name: name }, mesh);
    g.position = { x: 0, y: centreY, z: z } as Vec3;
    if (USE_MATERIALS) {
      g.mesh.materialOverride = await this.materials.create(`${name}Mat`, Finishes.bluedSteel());
    }
    return g;
  }

  private appendToRoot(n: Node): void {
    if (this.watchRoot) {
      this.watchRoot.children.append(n);
    }
  }

  private static makeBox(w: number, len: number, d: number, color: Color): CustomGeometry {
    const g: CustomGeometry = new CustomGeometry();
    g.topology = PrimitiveTopology.TRIANGLE_LIST;

    const hx: number = w * 0.5;
    const hy: number = len * 0.5;
    const hz: number = d * 0.5;

    const verts: Vec3[] = [
      { x: -hx, y: -hy, z: -hz } as Vec3,
      { x: hx, y: -hy, z: -hz } as Vec3,
      { x: hx, y: hy, z: -hz } as Vec3,
      { x: -hx, y: hy, z: -hz } as Vec3,
      { x: -hx, y: -hy, z: hz } as Vec3,
      { x: hx, y: -hy, z: hz } as Vec3,
      { x: hx, y: hy, z: hz } as Vec3,
      { x: -hx, y: hy, z: hz } as Vec3
    ];

    const norms: Vec3[] = [];
    const uvs: Vec2[] = [];
    const cols: Color[] = [];
    for (let i = 0; i < 8; i++) {
      norms.push({ x: 0, y: 0, z: 1 } as Vec3);
      uvs.push({ x: 0, y: 0 } as Vec2);
      cols.push(color);
    }

    const idx: number[] = [
      0, 1, 2, 2, 3, 0,
      4, 5, 6, 6, 7, 4,
      0, 4, 5, 5, 1, 0,
      1, 5, 6, 6, 2, 1,
      3, 2, 6, 6, 7, 3,
      3, 7, 4, 4, 0, 3
    ];

    g.vertices = verts;
    g.normals = norms;
    g.uvs = uvs;
    g.colors = cols;
    g.indices = idx;
    return g;
  }

  private static makeDisc(radius: number, segments: number, color: Color): CustomGeometry {
    const g: CustomGeometry = new CustomGeometry();
    g.topology = PrimitiveTopology.TRIANGLE_LIST;

    const verts: Vec3[] = [];
    const norms: Vec3[] = [];
    const uvs: Vec2[] = [];
    const cols: Color[] = [];
    const idx: number[] = [];

    verts.push({ x: 0, y: 0, z: 0 } as Vec3);
    norms.push({ x: 0, y: 0, z: 1 } as Vec3);
    uvs.push({ x: 0.5, y: 0.5 } as Vec2);
    cols.push(color);

    for (let i = 0; i <= segments; i++) {
      const a: number = (i / segments) * MathUtil.TWO_PI;
      const c: number = Math.cos(a);
      const s: number = Math.sin(a);
      verts.push({ x: c * radius, y: s * radius, z: 0 } as Vec3);
      norms.push({ x: 0, y: 0, z: 1 } as Vec3);
      uvs.push({ x: 0.5 + c * 0.5, y: 0.5 + s * 0.5 } as Vec2);
      cols.push(color);
    }
    for (let i = 1; i <= segments; i++) {
      idx.push(0); idx.push(i); idx.push(i + 1);
    }

    g.vertices = verts;
    g.normals = norms;
    g.uvs = uvs;
    g.colors = cols;
    g.indices = idx;
    return g;
  }
}