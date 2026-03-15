from django.shortcuts import render
from django.contrib.auth.decorators import login_required

# Essa "trava" garante que apenas pessoas com senha (como o supervisor) acessem o painel
@login_required(login_url='/admin/login/')
def dashboard_supervisor(request):
    # Por enquanto, estamos apenas carregando a tela. 
    # No futuro, o Python vai calcular os focos de dengue e enviar para cá!
    return render(request, 'dashboard.html')