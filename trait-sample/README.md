traitを使って設計してみる

いくつかトレイトのある言語をやってみたけど、いまいち上手く使えた感じがしないのでチラ裏的に書いてみようという試み

「走る」とか「食べる」とかをトレイトにするって例えを良く見る気がするけど、
「何をトレイトとしておけば」「何が組み合わせで実現できるのか」がしっくりこなかった

## 前提
言語は何でも良かったのでphp
あと掲載コードは抜粋というか、要所以外は躊躇無く省略してるし、phpの文法やお作法も適当
class, functionの`{`は改行だった気がするけど、これも圧縮のため適当

継承は縦、トレイトは横ってイメージを前提とする

```
+---------+
| class-A |
+---------+
     ^
     | extends
     |
+---------+
| class-B |
+---------+
     ^
     | extends
     |
+---------+
| class-C |
+---------+
```

```
+---------------------------------------+
|                class-A                |
|                                       |
|     use          use          use     |
| +---------+  +---------+  +---------+ |
| | trait-A |  | trait-B |  | trait-C | |
| +---------+  +---------+  +---------+ |
+---------------------------------------+
```

## バリデーションでtraitを使ってみる
細かいチェック項目をtraitで作っておき、任意の項目のバリデータをそれらの組み合わせだけで実現してみる

### parts
沢山用意する

```php:Regex.php
trait Regex {
    private function assertRegex($value, $pattern) {
        return preg_match($pattern, $value) === 1;
    }
}
```

```php:NotNull
trait NotNull {
    private function assertNotNull($value) {
        return !is_null($value);
    }
}
```

```php:Length
trait Length {
    private function assertMin($value, $length) {
        return $length <= strlen($value);
    }

    private function assertMax($value, $length) {
        return strlen($value) <= $length;
    }
}
```

```php:Character
trait Character {
    private function assertNoAtMark($value) {
        return strpos($value, '@') === false;
    }
}
```

### validator
要素毎にvalidatorを用意し、用意した部品を呼ぶ

```php:UserNameValidator
class UserNameValidator {
    use NotNull;
    use Length;
    use Character;

    public function isValid($value) {
        return
            $this->assertNotNull($value) and
            $this->assertMin($value, 4) and
            $this->assertMax($value, 8) and
            $this->assertNoAtMark($value);
    }
}
```

```php:UserIdValidator
class UserIdValidator {
    use NotNull;
    use Regex;
    use Character;

    public function isValid($value) {
        return
            $this->assertNotNull($value) and
            $this->assertRegex($value, '/user-.../') and
            $this->assertNoAtMark($value);
    }
}
```

### main
Validatorの`isValid`とでも名付けたメソッドを呼ぶ
中身は知らないけど、正しくチェックされるだろう、という感じで使う

```php:main.php
$userIdValidator = new UserIdValidator();
$userIdValidator->isValid('user-123');

$userNameValidator = new UserNameValidator();
$userNameValidator->isValid('j@ck');
```

### 感想
なぜだろう...？イマイチこれだー！という感じがしない...

+ `isValid`で実処理を隠蔽している部分に手間を感じる？
+ というか隠蔽するなら別に`trait`じゃあなくてstaticのUtilメソッドみたいなのでも実現できるし
+ 部品が小さすぎるのかな？
 + 大きさは関係ないと思うんだけど...
 + ただ、この部品が随時増えていく様な印象はない

## システム全体をtraitベースで設計してみる
上の感想を基に、ちょっと架空の仕様とシステムを考えてみた

### 会員制の買い物システム
新規入会、購入、会員情報の更新を行える
それぞれがサービスクラスで、実処理はtraitで実現する

#### 新規入会
+ 会員を作る
 + 会員を永続化
 + 住所を永続化
 + 決済方法を永続化
 + メールアドレスを永続化
+ 契約を作る
 + プランを永続化
+ 課金する
 + 会員の参照
 + プランの参照
 + プラン月額料金の課金
 + 決済方法の参照
 + 入会料を課金する
+ メールを送信する
 + メールアドレスを参照
 + 会員を参照
 + 受付メールを送信

#### 購入
+ 配送する
 + 在庫を引き当てる
 + 住所を参照
 + 配送業者に依頼する
+ 課金する
 + 決済方法の参照
 + 代金の課金
 + プランの参照
 + 発送代金の課金
+ メールを送信する
 + メールアドレスを参照
 + 会員を参照
 + 発送メールを送信

#### 会員情報の更新
+ 会員を更新
 + 会員を永続化
 + 住所を永続化
 + 決済方法を永続化
 + メールアドレスを永続化
+ メールを送信する
 + メールアドレスを参照
 + 変更メールを送信
+ 契約を作る
 + プランを永続化
 + 月額料金の永続化

### 部品
ただひたすら淡々と作る

```php:AddressRepository
trait AddressRepository {
    function saveAddress($address) {
        echo __FUNCTION__ . "\n";
    }
}
```

```php:MailAddressRepository
trait MailAddressRepository {
    function saveMailAddress($mailAddress) {
        echo __FUNCTION__ . "\n";
    }

    function findMailAddress($id) {
        echo __FUNCTION__ . "\n";
        return '';
    }
}
```

```php:MailRepository
trait MailRepository {
    function sendMailAtContract($member, $mailAddress) {
        echo __FUNCTION__ . "\n";
    }
}
```

```php:MemberRepository
trait MemberRepository {
    function saveMember($member) {
        echo __FUNCTION__ . "\n";
    }

    function findMember($id) {
        echo __FUNCTION__ . "\n";
        return '';
    }
}
```

```php:PaymentMethodRepository
trait PaymentMethodRepository {
    function savePaymentMethod($paymentMethod) {
        echo __FUNCTION__ . "\n";
    }

    function findPaymentMethod($id) {
        echo __FUNCTION__ . "\n";
        return '';
    }
}
```

```php:PaymentRepository
trait PaymentRepository {
    function payContractCharge($member, $paymentMethod) {
        echo __FUNCTION__ . "\n";
    }

    function payPlanFee($member, $paymentMethod, $plan) {
        echo __FUNCTION__ . "\n";
    }
}
```

```php:PlanRepository
trait PlanRepository {
    function savePlan($plan) {
        echo __FUNCTION__ . "\n";
    }

    function findPlan($id) {
        echo __FUNCTION__ . "\n";
        return '';
    }
}
```

### 新規申込サービス
traitを組み合わせてサービスクラスを作る
今回は本当に`use`のみ

```php:SignUpService
class SignUpService {
    use MemberRepository;
    use AddressRepository;
    use PaymentMethodRepository;
    use MailAddressRepository;
    use MailRepository;
    use PlanRepository;
    use PaymentRepository;
}
```

### 呼び元
API層（が仮にあるとし）からサービスの持つtraitのメソッドを連打する

```php:SignUpApi
$service = new SignUpService();

$service->saveMember(null);
$service->saveAddress(null);
$service->savePaymentMethod(null);
$service->saveMailAddress(null);

$service->savePlan(null);

$service->payContractCharge(
    $service->findMember(null),
    $service->findPaymentMethod(null)
);

$service->payPlanFee(
    $service->findMember(null),
    $service->findPaymentMethod(null),
    $service->findPlan(null)
);

$service->sendMailAtContract(
    $service->findMember(null),
    $service->findMailAddress(null)
);
```

### 感想
+ 隠蔽する部分の手間をなくしてみたので楽だった
 + それstaticのUtilで良いよね？感も無くなった
+ traitをひとつ作るコストの割に、再利用時のメリットが大きくなった気がする
 + 載せないけど、他のサービスは割とすぐ作れる気がする
+ 部品が充実するにつれて新たにサービスを作るのが楽になる感じがある
+ 仕様に書いた箇条書きとソースコードがピタリと一致する（様に書けた）
+ 会員リポジトリは会員参照リポジトリと会員永続化リポジトリくらいの粒度の方が良いかも
 + traitにメソッドが増えすぎるとuseするクラスと使われるメソッドの整理が難しくなりそう

## traitに対する感想
+ 一度作っておき、超気軽に再利用する、というのを念頭に置いてみた
+ 適切にモジュール化することで影響範囲を局所化出来る
+ 並行開発がしやすいと思う
+ 例えば上記の「新規申込」「購入」「会員情報の更新」をサービスクラスに複数人でベタ書き開発すると
 + 会員参照メソッドを作ったら3サービスに書き込んだり
 + 新規入会サービスの完成を待って購入サービスを作らなければいけなかったり
+ スケルトンコードが書きやすそうだし、そこから各自独立して開発できる
 + 最初にサービスクラスとtraitのメソッドだけ作って置いて、中身は独立開発で埋めていく
 + ちょうど掲載コード程度のスカスカ感
 + 設計レビューにもなるかな？
+ あー、単体テストもしやすいかな？

まぁ上で述べてる利点って適切にモジュール化していれば当然で、必ずしもtraitの利点ではないけれど
とりあえず「走る」とか「食べる」よりは「何をトレイトとしておけば」「何が組み合わせで実現できるのか」
が考えられた気がする

あ！
...DIしづらい...開発環境と本番環境で外部システムをモックにしたりが難しいかな？
また考えてみよう...

おしまい
