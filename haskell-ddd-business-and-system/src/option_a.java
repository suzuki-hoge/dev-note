public class Main {
    public static void main(String[] args) {
        apply("user-id-123", Item.PersonalComputer, Optional.<Option>empty());

        apply("user-id-123", Item.PersonalComputer, Optional.of(Option.Backup));

        apply("user-id-123", Item.PersonalComputer, Optional.of(Option.Replacement));

        apply("user-id-123", Item.Keyboard, Optional.of(Option.Backup));
    }

    public static String apply(String userId, Item item, Optional<Option> option) {
        if (findUser(userId) == null) {
            return "ユーザが見つかりません";
        } else if (item == Item.PersonalComputer && option == Optional.of(Option.Replacement)) {
            return "PCに交換オプションは付加出来ません";
        } else if (item == Item.Keyboard && option == Optional.of(Option.Backup)) {
            return "キーボードにバックアップオプションは付加出来ません";
        } else {
            String license = save(userId, item, option);
            sendMail(userId, item, option);
            return license;
        }
    }

    public static String findUser(String userId) {
        return "John";
    }

    public static String save(String userId, Item item, Optional<Option> option) {
        return "license-key-123";
    }

    public static void sendMail(String userId, Item item, Optional<Option> option) {
        System.out.print("メールを送信しました 件名: ");
        System.out.println(userId + " " + item.name() + " " + option.map(Enum::name).orElse(""));
    }
}
