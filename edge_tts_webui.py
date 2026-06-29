import asyncio
import os
import sys
import time
import socket
from datetime import datetime
import gradio as gr
import edge_tts

MAX_TEXT_LENGTH = 15000
SAVE_DIR = "saved_voices"
os.makedirs(SAVE_DIR, exist_ok=True)

try:
    voices_manager = asyncio.run(edge_tts.VoicesManager.create())
    ALL_VOICES_DATA = voices_manager.voices
except Exception as e:
    print(f"[ВНИМАНИЕ] Не удалось загрузить голоса из сети, включаем локальный пак: {e}")
    ALL_VOICES_DATA = [
        {"ShortName": "ru-RU-DmitryNeural", "Locale": "ru-RU", "Gender": "Male"},
        {"ShortName": "ru-RU-SvetlanaNeural", "Locale": "ru-RU", "Gender": "Female"},
        {"ShortName": "ru-RU-DariyaNeural", "Locale": "ru-RU", "Gender": "Female"},
        {"ShortName": "en-US-JennyNeural", "Locale": "en-US", "Gender": "Female"},
        {"ShortName": "en-US-GuyNeural", "Locale": "en-US", "Gender": "Male"},
        {"ShortName": "en-US-AriaNeural", "Locale": "en-US", "Gender": "Female"},
        {"ShortName": "en-US-ChristopherNeural", "Locale": "en-US", "Gender": "Male"},
        {"ShortName": "en-US-EricNeural", "Locale": "en-US", "Gender": "Male"},
        {"ShortName": "en-US-MichelleNeural", "Locale": "en-US", "Gender": "Female"},
        {"ShortName": "en-GB-SoniaNeural", "Locale": "en-GB", "Gender": "Female"},
        {"ShortName": "en-GB-RyanNeural", "Locale": "en-GB", "Gender": "Male"},
        {"ShortName": "en-GB-LibbyNeural", "Locale": "en-GB", "Gender": "Female"},
    ]

FAVORITE_LOCALES = ["ru-RU", "en-US", "en-GB"]
raw_locales = sorted(list(set(v["Locale"] for v in ALL_VOICES_DATA)))
LOCALES_CHOICES = []

for loc in FAVORITE_LOCALES:
    if loc in raw_locales:
        LOCALES_CHOICES.append((f"⭐ {loc}", loc))

for loc in raw_locales:
    if loc not in FAVORITE_LOCALES:
        LOCALES_CHOICES.append((loc, loc))

def get_voices_for_locale(locale_name):
    filtered = [v for v in ALL_VOICES_DATA if v["Locale"] == locale_name]
    
    males = [v for v in filtered if v["Gender"] == "Male"]
    females = [v for v in filtered if v["Gender"] == "Female"]
    
    choices = []
    
    if males:
        choices.append(("─── 👨 МУЖСКИЕ ГОЛОСА ───", "SEPARATOR_MALE"))
        for v in males:
            name = v['ShortName'].split('-')[-1].replace('Neural', '')
            choices.append((f"👨 {name}", v['ShortName']))
            
    if females:
        choices.append(("─── 👩 ЖЕНСКИЕ ГОЛОСА ───", "SEPARATOR_FEMALE"))
        for v in females:
            name = v['ShortName'].split('-')[-1].replace('Neural', '')
            choices.append((f"👩 {name}", v['ShortName']))
            
    return choices

INITIAL_RU_CHOICES = get_voices_for_locale("ru-RU")
INITIAL_RU_DEFAULT = next((val for name, val in INITIAL_RU_CHOICES if "SEPARATOR" not in val), None)

async def process_tts(text: str, voice_id: str, rate_val: int, pitch_val: int):
    if not text.strip():
        return None, "Ошибка: Поле текста не должно быть пустым!"
        
    current_length = len(text)
    if current_length > MAX_TEXT_LENGTH:
        return None, f"🛑 Текст слишком длинный ({current_length} симв.)!\nОфициальный лимит для одного запроса — {MAX_TEXT_LENGTH} символов.\nПожалуйста, сократите текст или разбейте его на части."
        
    if not voice_id or "SEPARATOR" in voice_id:
        return None, "Ошибка: Выберите конкретного диктора из списка, а не заголовок категории!"
        
    rate_str = f"+{rate_val}%" if rate_val >= 0 else f"{rate_val}%"
    pitch_str = f"+{pitch_val}Hz" if pitch_val >= 0 else f"{pitch_val}Hz"
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = os.path.join(SAVE_DIR, f"preview_{timestamp}.mp3")
    
    try:
        communicate = edge_tts.Communicate(
            text=text,
            voice=voice_id,
            rate=rate_str,
            pitch=pitch_str
        )
        await communicate.save(output_file)
        return output_file, f"✨ Успешно сгенерировано!\nСохранено в '{SAVE_DIR}'\nФайл: preview_{timestamp}.mp3\nДлина текста: {current_length} / {MAX_TEXT_LENGTH} симв."
    except Exception as e:
        return None, f"🔴 Ошибка генерации сервера: {str(e)}"

def gradio_wrapper(text, voice, rate, pitch):
    return asyncio.run(process_tts(text, voice, rate, pitch))

def update_voice_dropdown(locale):
    choices = get_voices_for_locale(locale)
    default_val = next((val for name, val in choices if "SEPARATOR" not in val), None)
    return gr.Dropdown(choices=choices, value=default_val)

def close_studio():
    print("\n" + "="*60)
    print("[INFO] Получена команда на закрытие Edge TTS Studio от пользователя.")
    
    for i in range(5, 0, -1):
        print(f"⏳ Сервер остановлен. Окно консоли закроется через: {i} сек.", end="\r", flush=True)
        time.sleep(1)
        
    print("\n[INFO] Отключение...")
    os._exit(0)

def show_confirm_panel():
    return gr.Row(visible=True)

def hide_confirm_panel():
    return gr.Row(visible=False)

def get_available_port(start_port=7860):
    port = start_port
    while port < 65535:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(("127.0.0.1", port))
                return port
            except OSError:
                print(f"[ПОРТ] {port} занят, проверяем следующий...")
                port += 1
    return start_port

with gr.Blocks(title="Edge TTS Global Studio", theme=gr.themes.Soft()) as demo:
    
    with gr.Row():
        with gr.Column(scale=5):
            gr.Markdown("# 🎙️ Microsoft Edge TTS — Глобальная Студия Озвучки")
            gr.Markdown("Вся мировая база нейросетевых голосов Azure/Edge в одном месте. Полностью бесплатно.")
        with gr.Column(scale=1):
            exit_btn = gr.Button("🛑 Выйти", variant="stop")
            
    with gr.Row(visible=False, variant="panel") as confirm_row:
        with gr.Column():
            gr.Markdown("### ⚠️ Вы действительно хотите выйти? Это полностью остановит локальный сервер.")
            with gr.Row():
                confirm_yes_btn = gr.Button("🛑 Да, выйти", variant="stop", scale=1)
                confirm_no_btn = gr.Button("🔄 Отмена", variant="secondary", scale=1)
    
    gr.Markdown("---")
    
    with gr.Row():
        with gr.Column(scale=2):
            input_text = gr.Textbox(
                label="Текст для озвучки", 
                placeholder="Вставь сюда сценарий своего ролика...", 
                lines=9
            )
            
            with gr.Row():
                lang_select = gr.Dropdown(
                    choices=LOCALES_CHOICES, 
                    value="ru-RU", 
                    label="🌐 Выбор языка / Региона"
                )
                voice_select = gr.Dropdown(
                    choices=INITIAL_RU_CHOICES, 
                    value=INITIAL_RU_DEFAULT, 
                    label="🗣️ Доступные дикторы"
                )
            
            with gr.Row():
                rate_slider = gr.Slider(minimum=-50, maximum=50, value=0, step=5, label="Скорость речи (%)")
                pitch_slider = gr.Slider(minimum=-50, maximum=50, value=0, step=2, label="Высота тона (Гц / Hz)")
                
            submit_btn = gr.Button("🚀 Сгенерировать аудиодорожку", variant="primary")
            
        with gr.Column(scale=1):
            output_audio = gr.Audio(label="Готовый аудиофайл (Слушать)", type="filepath")
            status_info = gr.Textbox(label="Статус и Путь сохранения", interactive=False, lines=5)

    lang_select.change(
        fn=update_voice_dropdown,
        inputs=[lang_select],
        outputs=[voice_select]
    )

    submit_btn.click(
        fn=gradio_wrapper,
        inputs=[input_text, voice_select, rate_slider, pitch_slider],
        outputs=[output_audio, status_info]
    )
    
    exit_btn.click(
        fn=show_confirm_panel,
        outputs=[confirm_row]
    )
    
    confirm_no_btn.click(
        fn=hide_confirm_panel,
        outputs=[confirm_row]
    )
    
    confirm_yes_btn.click(
        fn=close_studio,
        js="() => { setTimeout(() => { window.open('', '_self').close(); }, 800); }"
    )

if __name__ == "__main__":
    target_port = get_available_port(7860)
    if target_port != 7860:
        print(f"[ИНФО] Дефолтный порт 7860 был занят. Студия автоматически перенаправлена на порт: {target_port}")
        
    demo.launch(server_name="127.0.0.1", server_port=target_port, quiet=True, inbrowser=True)