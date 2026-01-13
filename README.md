# WireGuard Client Installer Web

Sistema web para geração automática de instaladores WireGuard para Windows.

## ✨ Funcionalidades
- Interface web amigável
- Preview da configuração antes da geração
- Geração de instalador `.exe`
- Execução como serviço no Windows
- Instalação automática do WireGuard
- Requer privilégios administrativos

## 🛠️ Tecnologias
- Python 3
- Flask
- PowerShell 7
- PS2EXE
- WireGuard

## 🚀 Como executar

```bash
pip install -r requirements.txt
python app.py

## Acesse:

http://localhost:5000


🔐 Segurança

Este sistema não deve ser exposto diretamente à internet.
Utilize VPN ou restrinja o acesso por firewall.

👨‍💻 Autor

Desenvolvido por Wilgner Kleyton Corrêa
Versão: 1.0