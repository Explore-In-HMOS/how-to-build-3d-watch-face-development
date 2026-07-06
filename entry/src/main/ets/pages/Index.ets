import { Scene } from '@kit.ArkGraphics3D';
import { WatchFaceEngine } from '../watchface/WatchFaceEngine';

@Entry
@Component
struct Index {
  private engine: WatchFaceEngine = new WatchFaceEngine();
  @State sceneOpt: SceneOptions | null = null;

  aboutToAppear(): void {
    this.engine.init()
      .then((scene: Scene): void => {
        this.sceneOpt = { scene: scene, modelType: ModelType.SURFACE } as SceneOptions;
        console.info('WatchFace: scene ready');
      })
      .catch((err: Object): void => {
        console.error(`WatchFace: init failed ${err}`);      
        });
  }

  onPageShow(): void {
    this.engine.resume();
  }

  onPageHide(): void {
    this.engine.suspend();
  }

  aboutToDisappear(): void {
    this.engine.destroy();
    this.sceneOpt = null;
  }

  build() {
    Stack() {
      if (this.sceneOpt) {
        Component3D(this.sceneOpt)
          .width('100%')
          .height('100%');
      } else {
        Text('Starting watch face...')
          .fontColor(Color.White)
          .fontSize(16);
      }
    }
    .backgroundColor(Color.Black)
    .width('100%')
    .height('100%');
  }
}
