package doc_path;

public enum Path {
    API設計方針書("ad.xxx.net/development/api/docs/readme.xlsx"),
    認証について("ad.xxx.net/development/authentication/docs/about.xlsx"),
    DB_会員テーブル("ad.xxx.net/database/tables/users.xlsx"),
    DB_購入物テーブル("ad.xxx.net/database/tables/items.xlsx"),
    サーバ構成資料("ad.xxx.net/infrastructure/docs/service-A003.xlsx"),
    物流システムAPI仕様書("www.xxx.net/development/logistics/api/api.html"),
    在庫管理システムAPI仕様書("www.xxx.net/development/warehouse/api/stocks.html"),
    ;

    private final String value;

    Path(String value) {
        this.value = value;
    }

    public void check() {
        // thisをどうにかする
        System.out.println(this.value);
    }

    public void open() {
        // thisをどうにかする
        System.out.println(this.value);
    }
}
