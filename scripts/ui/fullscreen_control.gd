extends Button
## Web requests run directly in the DOM click gesture, preserving user activation.
const WEB_SETUP := """
(() => {
 if (document.getElementById('salvage-fullscreen')) return;
 const style = document.createElement('style');
 style.textContent = `#salvage-fullscreen {position:fixed;z-index:1000;top:max(8px,env(safe-area-inset-top));right:max(8px,env(safe-area-inset-right));width:44px;height:44px;padding:11px;border:1px solid #657477;background:#132027cc;color:#cdd2d4;cursor:pointer;touch-action:manipulation} #salvage-fullscreen:focus-visible {outline:2px solid #a1e8c1} #salvage-fullscreen svg {width:100%;height:100%;fill:none;stroke:currentColor;stroke-width:2} #salvage-fullscreen-hint {position:fixed;z-index:1001;top:58px;right:8px;max-width:260px;background:#132027;color:#eee;padding:12px;font:14px sans-serif;pointer-events:none}`;
 document.head.appendChild(style);
 const button = document.createElement('button');
 button.id = 'salvage-fullscreen'; button.type = 'button';
 const hint = document.createElement('div');
 hint.id = 'salvage-fullscreen-hint'; hint.hidden = true; hint.setAttribute('role','status');
 document.body.append(button, hint);
 const active = () => document.fullscreenElement || document.webkitFullscreenElement;
 const update = () => {
  const on = !!active(); button.setAttribute('aria-label', on ? 'Exit fullscreen' : 'Enter fullscreen');
  button.title = button.getAttribute('aria-label'); button.setAttribute('aria-pressed', String(on));
  button.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="' + (on ? 'M3 9h6V3m6 0v6h6M3 15h6v6m6 0v-6h6' : 'M9 3H3v6m12-6h6v6M3 15v6h6m6 0h6v-6') + '"/></svg>';
 };
 let timer;
 const unavailable = () => {
  hint.textContent = 'Fullscreen is unavailable here. Try your browser menu or Add to Home Screen.';
  hint.hidden = false; clearTimeout(timer); timer = setTimeout(() => hint.hidden = true, 6000);
 };
 button.addEventListener('click', () => {
  hint.hidden = true;
  const canvas = document.querySelector('canvas');
  if (canvas) canvas.focus({preventScroll:true});
  const target = active() ? document : document.documentElement;
  const method = active() ? (document.exitFullscreen || document.webkitExitFullscreen) : (target.requestFullscreen || target.webkitRequestFullscreen);
  if (!method) { unavailable(); return; }
  try { const result = method.call(target); if (result && result.catch) result.catch(unavailable); } catch (_) { unavailable(); }
 });
 document.addEventListener('fullscreenchange', update);
 document.addEventListener('webkitfullscreenchange', update);
 update();
})();
"""

func _ready() -> void:
	custom_minimum_size = Vector2(44, 44)
	set_anchors_and_offsets_preset(PRESET_TOP_RIGHT)
	offset_left = -52
	offset_right = -8
	offset_top = 8
	offset_bottom = 52
	tooltip_text = "Toggle fullscreen"
	focus_mode = FOCUS_NONE
	if OS.has_feature("web"):
		JavaScriptBridge.eval(WEB_SETUP)
		hide()
	else:
		pressed.connect(func():
			var on := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if on else DisplayServer.WINDOW_MODE_FULLSCREEN))

func _draw() -> void:
	var center := size * 0.5
	for sign_x in [-1, 1]:
		for sign_y in [-1, 1]:
			var corner := center + Vector2(sign_x, sign_y) * 10
			draw_line(corner, corner - Vector2(sign_x * 6, 0), Color("cdd2d4"), 2, true)
			draw_line(corner, corner - Vector2(0, sign_y * 6), Color("cdd2d4"), 2, true)
