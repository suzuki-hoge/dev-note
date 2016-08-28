# Java8お試し
+ なんかそれっぽいキーワードを無理矢理使わせるための何か

## step01
クラスを作成するって言わない
要件だけ言う
筆を選べる
1. Rectangle, Triangle, Circleというクラスを作成する
 + Rectangleは`int width`と`int height`を持つ
 + Triangleは`int width`と`int height`を持つ
 + Circleは`int radius`を持つ
 + Rectangle, Triangle, Circleは`String color`を持つかもしれない
 + キーワード：Optional.of()
+ Rectangle, Triangle, Circleは `void draw()`を持つ
 + 実装は`sout("I'm Rectangle.");` 程度
 + ただし色を持つインスタンスの場合は`"I'm red Rectangle."`と出力する
 + キーワード：Optional.isPresent()（Optional.map, Optional.orElseでも可）
+ Rectangle, Triangle, Circleは `int area()`を持つ
 + 適当に面積計算をする 円周率は3で良い
+ Rectangle, Triangle, Circleは `void drawnBy(String name)`を持つ
 + 実装は`sout("I'm Rectangle, drawn by name.");` 程度
+ Rectangle, Triangle, Circleは `boolean hasColor()`を持つ
+ Rectangle, Triangle, Circleは `void thin()`を持つ
 + 自身の持つ色を再代入により`"red"`から`"thinned red"`に変更する
 + ただし元々色を持たない場合は変化無し
 + キーワード：Optional.map()
+ キーワード：デザインパターン, ストラテジパターン

### 動作確認例（抜粋）
```Java
rectangle.draw(); // I'm red Rectangle.
System.out.println(rectangle.area()); // 15
rectangle.drawnBy("IntelliJ"); // I'm Rectangle, drawn by IntelliJ.
System.out.println(rectangle.hasColor()); // true
```

## step02
1. Rectangle, Triangle, Circleをリストで持ち、すべてを一つずつ標準出力する（Lambda式記法とメソッド参照記法）
 + キーワード：Stream.forEach(), Lambda式, メソッド参照
+ Rectangle, Triangle, Circleをリストで持ち、すべてに`void draw()`させる（Lambda式記法とメソッド参照記法）
 + キーワード：Stream.forEach(), Lambda式, メソッド参照
+ Rectangle, Triangle, Circleをリストから、面積のリストを得る（Lambda式記法とメソッド参照記法）
 + キーワード：Stream.map(), Lambda式, メソッド参照
+ Rectangle, Triangle, Circleをリストで持ち、すべてに`void drawnBy(String name)`させる（Lambda式記法）
 + nameは全て同じ値で良い
 + キーワード：Stream.forEach(), Lambda式
+ Rectangle, Triangle, Circleをリストで持ち、色を持つインスタンスのみに`void draw()`させる
 + キーワード：Stream.filter(), Stream.forEach()
+ Rectangleのインスタンスを5つ持つ`List<Rectangle> rectangles`を生成する
 + キーワード：Stream.generate(), Stream.limit(), Stream.collect, Collectors.toList
+ Rectangle, Triangle, Circleをリストで持ち、色を持つインスタンスの先頭要素をOptionalで得る
 + キーワード：Stream.filter(), Stream.findFirst()
+ Rectangle, Triangle, Circleをリストで持ち、色を持つインスタンスの先頭要素を得る、ただし見つからない場合はRuntimeExceptionを投げる
 + キーワード：Stream.filter(), Stream.findFirst(), Stream.orElseThrow()

### 動作確認例（抜粋）
```Java
??? graphics = Arrays.asList(
    new Rectangle(3, 5, color),
    new Triangle(4, 8, color),
    new Circle(3, color),
    new Rectangle(3, 5, nonColor),
    new Triangle(4, 8, nonColor),
    new Circle(3, nonColor)
);
 graphics.stream().xxx(...
```

## step03
1. 2つの値を持つクラス Pairを作成する
 + `public class Pair<T1, T2> {`
  + キーワード：ジェネリクス
+ Pairクラスのインスタンスを生成するof()を実装する
 + `public static <T1, T2> Pair<T1, T2> of(T1 e1, T2 e2);`
+ コンストラクタを非公開にする
+ 一つ目の値を取得するgetLeft()を実装する
 + `public T1 getLeft() {`
+ 二つ目の値を取得するgetLeft()を実装する
 + `public T2 getRight() {`
+ T1, T2にはRectangle, Triangle, Circleしか持つことが出来ない様にする
  + キーワード：ジェネリクス(extends)

### 動作確認例（抜粋）
```Java
??? pair = Pair.of(rectangle, triangle);
System.out.println(pair.getLeft()); // rectangleのハッシュ値
System.out.println(pair.getRight()); // triangleのハッシュ値
```

## 参考
+ Strategy
 + [Strategy (ストラテジ)](http://www.nulab.co.jp/designPatterns/designPatterns2/designPatterns2-3.html)
+ Lambda
 + [Java8ラムダ式の使い方の基本](http://www.task-notes.com/entry/20150418/1429359646)
+ Optional
 + [Optional (Java Platform SE 8)](https://docs.oracle.com/javase/jp/8/api/java/util/Optional.html)
 + [Java 8 "Optional" ～ これからのnullとの付き合い方 ～](http://qiita.com/shindooo/items/815d651a72f568112910)
 + [Java8でのプログラムの構造を変えるOptional、ただしモナドではない](http://d.hatena.ne.jp/nowokay/20130524)
+ Stream
 + [Stream (Java Platform SE 8)](https://docs.oracle.com/javase/jp/8/api/java/util/stream/Stream.html)
 + [Java8のStreamを使いこなす](http://d.hatena.ne.jp/nowokay/20130504)
+ Generics
 + [ジェネリックス - Java 入門](http://java.keicode.com/lang/generics.php)
