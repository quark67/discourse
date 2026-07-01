import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { registerComposerPickerTab } from "discourse/lib/composer-picker";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const StubPanel = <template>
  <div class="stub-picker-panel"></div>
</template>;

acceptance("Composer picker - dynamically registered tabs", function (needs) {
  needs.user();
  needs.settings({ enable_emoji: false, enable_gifs: false });

  test("adds the toolbar button for a tab registered after boot", async function (assert) {
    await visit("/");

    // Registered after the app (and the composer-picker initializer) has
    // booted — the case a plugin initializer hits.
    registerComposerPickerTab({
      id: "test-picker-tab",
      icon: "star",
      title: "composer_picker.tabs.emoji",
      component: StubPanel,
      enabled: () => true,
    });

    await click("#create-topic");

    assert
      .dom(".insert-composer-emoji")
      .exists("the picker button is registered for the late-added tab");
  });
});
