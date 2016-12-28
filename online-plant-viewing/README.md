GitHubで差分を見る時にPlantUMLを描画させる

PlantUMLでいろんな図を書いているのですが、GitHubのPullRequestで差分として表示されるPlantUMLはただのテキストにしか見えないのでレビューし辛いです。

差分見る画面
<img width="1394" alt="diff.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/2fd7aeab-8e21-f29d-5e4c-9f041dba1aeb.png">

いちいちブランチを手元に持ってきて、エディタで開いて図にしなければなりません。

なんか良い方法はないかと思い探してみたら、Chrome拡張がありました。

[PlantUML Viewer](https://chrome.google.com/webstore/detail/plantuml-viewer/legbfeljfbjgfifnkmpoajgpgejojooj?hl=ja)

入れるだけです。

PullRequestの画面からファイルの画面まで行って、直接テキストで見るボタンを押す
<img width="1394" alt="raw.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/9325e51f-3d76-3ff2-bbcf-ccaeb73ec94a.png">

拡張入れる前
<img width="1394" alt="text.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/b3365884-1b7b-830b-5bb6-0dcd25836b6a.png">

入れた後　図だ！！
<img width="1394" alt="viewing.png" src="https://qiita-image-store.s3.amazonaws.com/0/113398/24045856-ef6b-c1ff-32a0-2b8cdd4867e5.png">

らくちんだ

適当なファイルを僕のGitHubに置いてあるので、適当に試しに見てみるのにでも使ってみてください。

+ [クラス](https://raw.githubusercontent.com/suzuki-hoge/dev-note/1827d2aea34b6ce5e285bda37df8bb5b3d66cb6b/online-plant-viewing/doc/foo_class.puml)
+ [シーケンス](https://raw.githubusercontent.com/suzuki-hoge/dev-note/1827d2aea34b6ce5e285bda37df8bb5b3d66cb6b/online-plant-viewing/doc/foo_seq.puml)
+ [ステート](https://raw.githubusercontent.com/suzuki-hoge/dev-note/1827d2aea34b6ce5e285bda37df8bb5b3d66cb6b/online-plant-viewing/doc/foo_state.puml)
