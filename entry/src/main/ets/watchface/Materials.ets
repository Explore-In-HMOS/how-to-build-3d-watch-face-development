import {
  Scene,
  SceneResourceFactory,
  SceneResourceParameters,
  Material,
  MaterialType,
  MetallicRoughnessMaterial,
  Vec4
} from '@kit.ArkGraphics3D';

export class PbrSpec {
  r: number = 1;
  g: number = 1;
  b: number = 1;
  a: number = 1;
  roughness: number = 0.5;
  metallic: number = 1.0;
  reflectance: number = 0.5;
  emR: number = 0;
  emG: number = 0;
  emB: number = 0;
  receivesShadow: boolean = false;

  constructor(r: number, g: number, b: number, roughness: number, metallic: number,
    reflectance: number) {
    this.r = r;
    this.g = g;
    this.b = b;
    this.roughness = roughness;
    this.metallic = metallic;
    this.reflectance = reflectance;
  }
}

export class Finishes {
  static silverDial(): PbrSpec {
    const s: PbrSpec = new PbrSpec(0.86, 0.88, 0.90, 0.34, 0.30, 0.50);
    s.receivesShadow = true;
    return s;
  }

  static bluedSteel(): PbrSpec {
    const s: PbrSpec = new PbrSpec(0.05, 0.12, 0.34, 0.16, 1.0, 0.60);
    s.emR = 0.02;
    s.emG = 0.05;
    s.emB = 0.14;
    return s;
  }

  static redAccent(): PbrSpec {
    const s: PbrSpec = new PbrSpec(0.86, 0.11, 0.07, 0.40, 0.0, 0.45);
    s.emR = 0.18;
    s.emG = 0.02;
    s.emB = 0.0;
    return s;
  }

  static roseGold(): PbrSpec {
    return new PbrSpec(0.86, 0.55, 0.42, 0.20, 1.0, 0.55);
  }

  static lumeTip(): PbrSpec {
    const s: PbrSpec = new PbrSpec(0.70, 0.95, 0.85, 0.6, 0.0, 0.35);
    s.emR = 0.25;
    s.emG = 0.55;
    s.emB = 0.45;
    return s;
  }
}

export class Materials {
  private factory: SceneResourceFactory;

  constructor(scene: Scene) {
    this.factory = scene.getResourceFactory();
  }

  async create(name: string, spec: PbrSpec): Promise<MetallicRoughnessMaterial> {
    const params: SceneResourceParameters = { name: name };
    const base: Material =
      await this.factory.createMaterial(params, MaterialType.METALLIC_ROUGHNESS);
    const mat: MetallicRoughnessMaterial = base as MetallicRoughnessMaterial;

    const bc = mat.baseColor;
    bc.factor = {
      x: spec.r,
      y: spec.g,
      z: spec.b,
      w: spec.a
    } as Vec4;
    mat.baseColor = bc;

    const mp = mat.material;
    mp.factor = {
      x: spec.roughness,
      y: spec.metallic,
      z: spec.reflectance,
      w: 1
    } as Vec4;
    mat.material = mp;

    const em = mat.emissive;
    em.factor = {
      x: spec.emR,
      y: spec.emG,
      z: spec.emB,
      w: 1
    } as Vec4;
    mat.emissive = em;

    mat.shadowReceiver = spec.receivesShadow;

    return mat;
  }
}