//Processingで文字を分解するプログラム。
//時計回りと反時計回りのパスの判別を分解に応用。全角では反時計回りが通常。時計回りがContour（排他論理和？）。半角は逆？。
//現時点は半角と全角が混ざると分解不能。別々に渡せば分解可能。

//パス取得の参考 https://wcs.hatenablog.com/entry/2014/08/02/184622
//パス取得などの参考 p5jsプログラム https://github.com/kumamuk-git/moji_bunkai_p5js
//時計回りと反時計回りのパス判別方法の参考
//https://www5d.biglobe.ne.jp/noocyte/Programming/Geometry/PolygonMoment-jp.html#AreaAndDirection

//以下、作業中

import java.awt.Font;
import java.awt.font.FontRenderContext;
import java.awt.image.BufferedImage;
import java.awt.geom.PathIterator;
import java.util.ArrayList;
import java.util.List;

//Pathを生成する
PathIterator createOutline(String name, int size, String text, float x, float y) {
  FontRenderContext frc =
    new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB)
      .createGraphics()
      .getFontRenderContext();

  Font font = new Font(name, Font.PLAIN, size);

  PathIterator iter = font.createGlyphVector(frc, text)
    .getOutline(x, y)
    .getPathIterator(null);

  return iter;
}

//coordを出力する汎用関数
void printCoord(String fontName, String text) {
  PathIterator iter = createOutline(fontName, 50, text, 10, 40);
  float coords[] = new float[6];
  while (!iter.isDone()) {
    int type = iter.currentSegment(coords);
    println(type,coords[0], coords[1], coords[2],coords[3],coords[4],coords[5]);
    iter.next();
  }
}

//PointData クラス
class PointData{
  private int type; //描画タイプ
  private float coords[]; //描画制御点
  PointData(int type, float coords[]){
    this.type = type;
    this.coords = coords;
  }
}

//genShapeList関数 [[分解後の図形パス],[分解後の図形パス],...]の形でリストを返す。
List<List<PointData>> genShapeList(String fontName,String text) {
  PathIterator iter = createOutline(fontName, 50, text, 10, 40);
  List<List<PointData>>shapeList = new ArrayList<List<PointData>>();
    
  float startX=0.,startY=0.,preX=0.,preY=0.;
  float X=0.,Y=0.;
  float S =0;
  int baseFlag = 0; //符号の基準となるフラグ。全角日本語と半角英数字でパスの回転方向が異なったので設定。1：全角日本語、-1：英数字
  List<Integer>flagList = new ArrayList<Integer>(); //検証用
  List<PointData>pathList = new ArrayList<PointData>();
  while (!iter.isDone()){
    float coords[] = new float[6];
    int type = iter.currentSegment(coords);
    switch (type) {
      case PathIterator.SEG_MOVETO: // beginning of new path 0
        startX = coords[0];
        startY = coords[1];
        S = 0; //初期化
        preX = startX;
        preY = startY;
        pathList = new ArrayList<PointData>();
        pathList.add(new PointData(type,coords));
        break;
        
      case PathIterator.SEG_LINETO: //1
          X = coords[0];
          Y = coords[1];
          S += preX * Y - preY * X;
          preX = X;
          preY = Y;
          pathList.add(new PointData(type,coords));
        break;
        
       case PathIterator.SEG_QUADTO: //2
          X = coords[2];
          Y = coords[3];
          S += preX * Y - preY * X;
          preX = X;
          preY = Y;
          pathList.add(new PointData(type,coords));
        break;
        
      case PathIterator.SEG_CUBICTO: //3
          X = coords[4];
          Y = coords[5];
          S += preX * Y - preY * X;
          preX = X;
          preY = Y;
          pathList.add(new PointData(type,coords));
        break;
        
      case PathIterator.SEG_CLOSE: //4
        pathList.add(new PointData(type,coords));
        S += preX * startY - preY * startX;
        //S <0ならば反時計回り S>0ならば時計回り。
        if(baseFlag==0) //符号の基準となるフラグ。全角日本語と半角英数字でパスの回転方向が異なったので設定。1：全角日本語、-1：英数字
          if(S<0){
            baseFlag=1;
          }else if(S>0){
            baseFlag=-1;
          }
          
        if(baseFlag*S<0){ //反時計回り
          flagList.add(0); //検証用
          shapeList.add(pathList); //反時計回りなら新たにパスのリストを作成
        }
        else if(baseFlag*S>0){ //時計回り　
          flagList.add(1); //検証用
          shapeList.get(shapeList.size()-1).addAll(pathList); //時計回りなら打ち消すパスを最後のパスリストに追加
        }
      else{
      print("ERROR S==0");
      }
        break;
      default:
        throw new RuntimeException("should not reach here");
    }
    iter.next();
  }
  //println(flagList);　検証用
  //return flagList; //フラグを返す場合　検証用
  return shapeList;
}

void drawText(List<PointData>pathList) {
  PointData path;
  float coords[] = new float[6];
  int type;
  int flag = 0;
  int pathListLength = pathList.size();
  for(int j=0;j<pathListLength;j++){
    path = pathList.get(j);
    type = path.type;
    coords = path.coords;
    switch (type) {
      case PathIterator.SEG_MOVETO: // beginning of new path 0
        if(flag==0){
          beginShape();
        }
        if(flag>=1){
          beginContour();
        }
        vertex(coords[0], coords[1]);
        break;
      case PathIterator.SEG_LINETO:  //1
        vertex(coords[0], coords[1]);
        break;
      case PathIterator.SEG_QUADTO://2
        quadraticVertex(coords[0], coords[1], coords[2], coords[3]);
        break;
      case PathIterator.SEG_CUBICTO: //3
        bezierVertex(coords[0], coords[1], coords[2], coords[3], coords[4], coords[5]);
        break;
      case PathIterator.SEG_CLOSE: //4
        if(flag>=1){
          endContour();
        }
        flag++;
        break;
      default:
        throw new RuntimeException("should not reach here");
    }
  }
  endShape(CLOSE);
}

//以下、setup,draw
List<List<PointData>>shapeListForDraw;
void setup(){
  size(800,800);
  String[] fontList;
  fontList= PFont.list();
  String fontName = fontList[276];
  String text = "テスト"; //対象となる文章
  
  printCoord(fontName, text); //描画タイプ、描画制御点を出力する関数
  shapeListForDraw= genShapeList(fontName,text); //分解後のパスのリストを返す関数
  println(fontName);
}

int index=0;
void draw(){
  if(frameCount%30==0){
    for(int i=0;i<index && i<shapeListForDraw.size();i++){
      drawText(shapeListForDraw.get(i)); //描画する関数
    }
  index++;
  }
}
