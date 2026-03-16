import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database_helper.dart';

// =============================================================================
// VARIÁVEL GLOBAL DO SERVIDOR (Nosso Servidor Oficial do Render)
// =============================================================================
String baseUrl = 'https://endemias-vila-rica.onrender.com';

void main() => runApp(const EndemiasApp());

class EndemiasApp extends StatelessWidget {
  const EndemiasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Endemias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
        ),
      ),
      home: const TelaLogin(),
    );
  }
}

// =============================================================================
// TELA DE LOGIN COM CONFIGURAÇÃO DE NGROK E AUTENTICAÇÃO REAL
// =============================================================================
class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _ocultarSenha = true;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracaoServidor();
  }

  Future<void> _carregarConfiguracaoServidor() async {
    String? urlSalva = await DatabaseHelper.instance.lerCache('api_url');
    if (urlSalva != null && urlSalva.isNotEmpty) {
      baseUrl = urlSalva;
    }
  }

  void _abrirConfiguracaoServidor() {
    TextEditingController urlController = TextEditingController(text: baseUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Configuração do Servidor (TI)',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Insira o endereço do servidor (sem a barra / no final):',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'Ex: https://endemias-vila-rica.onrender.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
            onPressed: () async {
              String novaUrl = urlController.text.trim();
              if (novaUrl.endsWith('/')) {
                novaUrl = novaUrl.substring(0, novaUrl.length - 1);
              }
              baseUrl = novaUrl;
              await DatabaseHelper.instance.salvarCache('api_url', novaUrl);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Servidor atualizado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'SALVAR URL',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fazerLogin() async {
    if (_usuarioController.text.trim().isEmpty ||
        _senhaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe seu usuário e senha.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      final resposta = await http
          .post(
            Uri.parse('$baseUrl/api/login/'),
            headers: {
              "Content-Type": "application/json",
              "ngrok-skip-browser-warning": "true",
            },
            body: jsonEncode({
              "username": _usuarioController.text.trim(),
              "password": _senhaController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);
        final token = dados['token'];

        await DatabaseHelper.instance.salvarCache('token_auth', token);
        await DatabaseHelper.instance.salvarCache(
          'agente_logado',
          _usuarioController.text.trim(),
        );

        setState(() => _carregando = false);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TelaInicial()),
          );
        }
      } else {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário ou senha incorretos!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão. Servidor offline?'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: _abrirConfiguracaoServidor,
            tooltip: 'Configurar Servidor',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/mosquito.jpg', height: 120),
              ),
              const SizedBox(height: 24),
              const Text(
                'SISTEMA DE ENDEMIAS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prefeitura de Vila Rica - MT',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),

              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Acesso do Agente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usuarioController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Usuário ou Matrícula',
                          prefixIcon: Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _senhaController,
                        obscureText: _ocultarSenha,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarSenha
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _ocultarSenha = !_ocultarSenha;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _carregando ? null : _fazerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _carregando
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ENTRAR',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Secretaria Municipal de Saúde',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TELA INICIAL
// =============================================================================
class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});
  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  final List<Map<String, dynamic>> bairrosVilaRica = [
    {"nome": "Vila Nova", "imoveis": 621, "quarteiroes": 31},
    {"nome": "Cidade Jardim", "imoveis": 567, "quarteiroes": 35},
    {"nome": "Setor Norte", "imoveis": 808, "quarteiroes": 33},
    {"nome": "Bela Vista", "imoveis": 687, "quarteiroes": 31},
    {"nome": "São Pedro", "imoveis": 179, "quarteiroes": 8},
    {"nome": "Tiradentes", "imoveis": 493, "quarteiroes": 22},
    {"nome": "Inconfidentes", "imoveis": 1403, "quarteiroes": 48},
    {"nome": "Setor Oeste", "imoveis": 1141, "quarteiroes": 63},
    {"nome": "Cristo Rei", "imoveis": 231, "quarteiroes": 14},
    {"nome": "Setor Sul", "imoveis": 708, "quarteiroes": 37},
  ];

  Map<String, dynamic>? bairroSelecionado;
  int? cicloSelecionado;
  Map<String, dynamic>? semanaSelecionada;
  List<Map<String, dynamic>> todasSemanas = [];
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    _gerarCalendarioEpidemiologico();
    _sugerirCicloESemanaAtual();
  }

  void _gerarCalendarioEpidemiologico() {
    DateTime dataAtual = DateTime(2026, 1, 4);
    for (int i = 1; i <= 52; i++) {
      DateTime dataFim = dataAtual.add(const Duration(days: 6));
      int ciclo = 1;
      if (i >= 9 && i <= 17)
        ciclo = 2;
      else if (i >= 18 && i <= 26)
        ciclo = 3;
      else if (i >= 27 && i <= 34)
        ciclo = 4;
      else if (i >= 35 && i <= 43)
        ciclo = 5;
      else if (i >= 44 && i <= 52)
        ciclo = 6;
      String strInicio =
          "${dataAtual.day.toString().padLeft(2, '0')}/${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year}";
      String strFim =
          "${dataFim.day.toString().padLeft(2, '0')}/${dataFim.month.toString().padLeft(2, '0')}/${dataFim.year}";
      todasSemanas.add({
        "semana": i,
        "inicio": strInicio,
        "fim": strFim,
        "ciclo": ciclo,
        "dataInicio": dataAtual,
        "dataFim": dataFim,
      });
      dataAtual = dataAtual.add(const Duration(days: 7));
    }
  }

  void _sugerirCicloESemanaAtual() {
    DateTime hoje = DateTime.now();
    for (var s in todasSemanas) {
      if (hoje.isAfter(s['dataInicio'].subtract(const Duration(days: 1))) &&
          hoje.isBefore(s['dataFim'].add(const Duration(days: 1)))) {
        setState(() {
          cicloSelecionado = s['ciclo'];
          semanaSelecionada = s;
        });
        break;
      }
    }
  }

  Future<void> _sincronizarOffline() async {
    setState(() => _sincronizando = true);
    try {
      int sucessoImoveis = 0;
      final imoveisPendentes = await DatabaseHelper.instance
          .buscarImoveisPendentes();
      for (var im in imoveisPendentes) {
        Map<String, dynamic> dadosEnvio = Map.from(im);
        int idLocal = dadosEnvio.remove('id_local');
        dadosEnvio.remove('sincronizado');
        final resp = await http
            .post(
              Uri.parse('$baseUrl/api/imoveis/'),
              headers: {
                "Content-Type": "application/json",
                "ngrok-skip-browser-warning": "true",
              },
              body: jsonEncode(dadosEnvio),
            )
            .timeout(const Duration(seconds: 5));

        if (resp.statusCode == 201 || resp.statusCode == 200) {
          int idReal = jsonDecode(resp.body)['id'];
          await DatabaseHelper.instance.marcarImovelComoSincronizado(idLocal);
          await DatabaseHelper.instance.atualizarIdImovelNasVisitas(
            "TEMP_$idLocal",
            idReal,
          );
          sucessoImoveis++;
        }
      }

      int sucessoVisitas = 0;
      final visitasPendentes = await DatabaseHelper.instance
          .buscarVisitasPendentes();
      for (var visita in visitasPendentes) {
        Map<String, dynamic> dadosEnvio = Map.from(visita);
        int idLocal = dadosEnvio.remove('id_local');
        dadosEnvio.remove('sincronizado');
        if (dadosEnvio['imovel'].toString().startsWith('TEMP')) continue;
        final resp = await http
            .post(
              Uri.parse('$baseUrl/api/visitas/'),
              headers: {
                "Content-Type": "application/json",
                "ngrok-skip-browser-warning": "true",
              },
              body: jsonEncode(dadosEnvio),
            )
            .timeout(const Duration(seconds: 5));

        if (resp.statusCode == 201 || resp.statusCode == 200) {
          await DatabaseHelper.instance.marcarComoSincronizado(idLocal);
          sucessoVisitas++;
        }
      }

      if (imoveisPendentes.isEmpty && visitasPendentes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tudo já está sincronizado!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sincronizado: $sucessoImoveis imóvel(is) e $sucessoVisitas visita(s)!',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro de rede. Verifique se o servidor está online em $baseUrl',
          ),
        ),
      );
    }
    setState(() => _sincronizando = false);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> semanasDoCiclo = cicloSelecionado == null
        ? []
        : todasSemanas.where((s) => s['ciclo'] == cicloSelecionado).toList();
    bool habilitarInspecao =
        bairroSelecionado != null &&
        cicloSelecionado != null &&
        semanaSelecionada != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Endemias'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vila Rica - MT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Column(
                children: [
                  const Text(
                    '📅 Período Epidemiológico',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Ciclo'),
                          initialValue: cicloSelecionado,
                          items: [1, 2, 3, 4, 5, 6]
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    '$cº Ciclo',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            cicloSelecionado = v;
                            semanaSelecionada = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Semana',
                          ),
                          initialValue: semanaSelecionada,
                          items: semanasDoCiclo
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    'Semana ${s['semana']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => semanaSelecionada = v),
                        ),
                      ),
                    ],
                  ),
                  if (semanaSelecionada != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'De ${semanaSelecionada!['inicio']} até ${semanaSelecionada!['fim']}',
                      style: TextStyle(
                        color: Colors.purple[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: const InputDecoration(
                labelText: 'Bairro de Trabalho',
              ),
              initialValue: bairroSelecionado,
              items: bairrosVilaRica
                  .map(
                    (b) => DropdownMenuItem(value: b, child: Text(b['nome'])),
                  )
                  .toList(),
              onChanged: (v) => setState(() => bairroSelecionado = v),
            ),
            if (bairroSelecionado != null) ...[
              const SizedBox(height: 10),
              Text(
                'Meta: ${bairroSelecionado!['imoveis']} imóveis | ${bairroSelecionado!['quarteiroes']} quarteirões',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: bairroSelecionado == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => TelaCadastroImovel(
                          nomeBairro: bairroSelecionado!['nome'],
                        ),
                      ),
                    ),
              icon: const Icon(Icons.add_home_work, color: Colors.white),
              label: const Text(
                '1. Mapear Novo Imóvel',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: !habilitarInspecao
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => TelaListaImoveis(
                          nomeBairro: bairroSelecionado!['nome'],
                          cicloId: cicloSelecionado!,
                          semanaId: semanaSelecionada!['semana'],
                          totalQuarteiroes: bairroSelecionado!['quarteiroes'],
                          apenasPE: false,
                        ),
                      ),
                    ),
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text(
                '2. Inspeção de Rotina',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: !habilitarInspecao
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => TelaListaImoveis(
                          nomeBairro: bairroSelecionado!['nome'],
                          cicloId: cicloSelecionado!,
                          semanaId: semanaSelecionada!['semana'],
                          totalQuarteiroes: bairroSelecionado!['quarteiroes'],
                          apenasPE: true,
                        ),
                      ),
                    ),
              icon: const Icon(Icons.factory, color: Colors.white),
              label: const Text(
                '3. Inspeção de PE',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => TelaHistoricoVisitas(semanas: todasSemanas),
                ),
              ),
              icon: const Icon(Icons.history, color: Colors.white),
              label: const Text(
                '4. Histórico Agrupado',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => TelaRelatorios(
                    bairros: bairrosVilaRica,
                    semanas: todasSemanas,
                  ),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                '5. Gerar Relatórios',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _sincronizando ? null : _sincronizarOffline,
              icon: _sincronizando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.cloud_sync, color: Colors.white),
              label: Text(
                _sincronizando ? 'Sincronizando...' : '6. Sincronizar Offline',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TELA DE MAPEAMENTO E EDIÇÃO DE IMÓVEIS
// =============================================================================
class TelaCadastroImovel extends StatefulWidget {
  final String nomeBairro;
  final Map<String, dynamic>? imovelExistente;
  const TelaCadastroImovel({
    super.key,
    required this.nomeBairro,
    this.imovelExistente,
  });
  @override
  State<TelaCadastroImovel> createState() => _TelaCadastroImovelState();
}

class _TelaCadastroImovelState extends State<TelaCadastroImovel> {
  bool enviando = false;
  double? lat, lng;
  final _end = TextEditingController(),
      _num = TextEditingController(),
      _quart = TextEditingController();
  String _tipo = 'Residencial';

  @override
  void initState() {
    super.initState();
    if (widget.imovelExistente != null) {
      _end.text = widget.imovelExistente!['endereco'] ?? '';
      _num.text = widget.imovelExistente!['numero']?.toString() ?? '';
      _quart.text = widget.imovelExistente!['quarteirao']?.toString() ?? '';
      String sigla = widget.imovelExistente!['tipo'] ?? 'R';
      if (sigla == 'C')
        _tipo = 'Comercial';
      else if (sigla == 'TB')
        _tipo = 'Terreno Baldio';
      else if (sigla == 'PE')
        _tipo = 'Ponto Estratégico';
      try {
        String loc = widget.imovelExistente!['localizacao'] ?? '';
        if (loc.contains('POINT')) {
          var coords = loc
              .replaceAll('POINT(', '')
              .replaceAll(')', '')
              .split(' ');
          lng = double.parse(coords[0]);
          lat = double.parse(coords[1]);
        }
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.imovelExistente != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Imóvel' : 'Mapear Novo Imóvel'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bairro: ${widget.nomeBairro}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                Position p = await Geolocator.getCurrentPosition();
                setState(() {
                  lat = p.latitude;
                  lng = p.longitude;
                });
              },
              icon: Icon(
                lat == null ? Icons.gps_not_fixed : Icons.gps_fixed,
                color: lat == null ? const Color(0xFF1E3A8A) : Colors.green,
              ),
              label: Text(
                lat == null
                    ? 'Atualizar GPS (Obrigatório)'
                    : 'GPS Atualizado com Sucesso',
                style: TextStyle(
                  color: lat == null ? const Color(0xFF1E3A8A) : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: lat == null ? const Color(0xFF1E3A8A) : Colors.green,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _end,
              decoration: const InputDecoration(labelText: 'Nome da Rua'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _num,
                    decoration: const InputDecoration(labelText: 'Número'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _quart,
                    decoration: const InputDecoration(labelText: 'Quarteirão'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de Imóvel'),
              items: const [
                DropdownMenuItem(
                  value: 'Residencial',
                  child: Text('Residencial'),
                ),
                DropdownMenuItem(value: 'Comercial', child: Text('Comercial')),
                DropdownMenuItem(
                  value: 'Terreno Baldio',
                  child: Text('Terreno Baldio'),
                ),
                DropdownMenuItem(
                  value: 'Ponto Estratégico',
                  child: Text('Ponto Estratégico'),
                ),
              ],
              onChanged: (String? newValue) =>
                  setState(() => _tipo = newValue!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      if (lat == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, capture o GPS!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (isEdit &&
                          widget.imovelExistente!['id'].toString().startsWith(
                            'TEMP',
                          )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Imóveis criados offline não podem ser editados até serem sincronizados com a base.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      setState(() => enviando = true);
                      String tipoSigla = 'R';
                      if (_tipo == 'Comercial')
                        tipoSigla = 'C';
                      else if (_tipo == 'Terreno Baldio')
                        tipoSigla = 'TB';
                      else if (_tipo == 'Ponto Estratégico')
                        tipoSigla = 'PE';
                      var dadosImovel = {
                        "endereco": _end.text,
                        "numero": _num.text,
                        "bairro": widget.nomeBairro,
                        "quarteirao": _quart.text,
                        "tipo": tipoSigla,
                        "localizacao": "POINT($lng $lat)",
                      };
                      try {
                        if (isEdit) {
                          await http
                              .put(
                                Uri.parse(
                                  '$baseUrl/api/imoveis/${widget.imovelExistente!['id']}/',
                                ),
                                headers: {
                                  "Content-Type": "application/json",
                                  "ngrok-skip-browser-warning": "true",
                                },
                                body: jsonEncode(dadosImovel),
                              )
                              .timeout(const Duration(seconds: 4));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Imóvel atualizado no servidor!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          await http
                              .post(
                                Uri.parse('$baseUrl/api/imoveis/'),
                                headers: {
                                  "Content-Type": "application/json",
                                  "ngrok-skip-browser-warning": "true",
                                },
                                body: jsonEncode(dadosImovel),
                              )
                              .timeout(const Duration(seconds: 4));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Imóvel mapeado e salvo!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (!isEdit) {
                          try {
                            await DatabaseHelper.instance.inserirImovel(
                              dadosImovel,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Salvo no Modo Offline! Sincronize na base.',
                                ),
                                backgroundColor: Colors.deepPurple,
                              ),
                            );
                            if (mounted) Navigator.pop(context);
                          } catch (eBanco) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro no Banco: $eBanco'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => enviando = false);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sem internet para editar imóvel no servidor.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() => enviando = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: enviando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEdit ? 'ATUALIZAR IMÓVEL' : 'SALVAR MAPEAMENTO',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// LISTA DE IMÓVEIS
// =============================================================================
class TelaListaImoveis extends StatefulWidget {
  final String nomeBairro;
  final int cicloId;
  final int semanaId;
  final int totalQuarteiroes;
  final bool apenasPE;
  const TelaListaImoveis({
    super.key,
    required this.nomeBairro,
    required this.cicloId,
    required this.semanaId,
    required this.totalQuarteiroes,
    required this.apenasPE,
  });
  @override
  State<TelaListaImoveis> createState() => _TelaListaImoveisState();
}

class _TelaListaImoveisState extends State<TelaListaImoveis> {
  Future<List<dynamic>> _carregarImoveis() async {
    List<dynamic> imoveis = [];
    try {
      final r = await http
          .get(
            Uri.parse('$baseUrl/api/imoveis/'),
            headers: {"ngrok-skip-browser-warning": "true"},
          )
          .timeout(const Duration(seconds: 5));

      await DatabaseHelper.instance.salvarCache(
        'imoveis',
        utf8.decode(r.bodyBytes),
      );
      imoveis = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (e) {
      final cacheStr = await DatabaseHelper.instance.lerCache('imoveis');
      if (cacheStr != null) {
        imoveis = jsonDecode(cacheStr);
      } else {
        throw Exception('Sem dados offline.');
      }
    }
    final pendentes = await DatabaseHelper.instance.buscarImoveisPendentes();
    for (var p in pendentes) {
      imoveis.add({
        "id": "TEMP_${p['id_local']}",
        "endereco": p['endereco'],
        "numero": p['numero'],
        "bairro": p['bairro'],
        "quarteirao": p['quarteirao'],
        "tipo": p['tipo'],
      });
    }
    return imoveis
        .where(
          (i) =>
              i['bairro'] == widget.nomeBairro &&
              (widget.apenasPE ? i['tipo'] == 'PE' : true),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.apenasPE
              ? 'Inspeção PE: ${widget.nomeBairro}'
              : 'Rotina: ${widget.nomeBairro}',
        ),
        backgroundColor: widget.apenasPE ? Colors.red[800] : Colors.orange[800],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _carregarImoveis(),
        builder: (c, s) {
          if (s.hasError)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'Nenhum dado salvo no celular.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Abra o app no Wi-Fi uma vez para baixar.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());

          List<dynamic> imoveis = s.data!;
          Map<String, Map<String, List<dynamic>>> agrupado = {};
          for (int i = 1; i <= widget.totalQuarteiroes; i++) {
            String qStr = i.toString().padLeft(2, '0');
            agrupado[qStr] = {};
          }

          for (var im in imoveis) {
            String rawQ = im['quarteirao']?.toString().trim() ?? "";
            int? parsedQ = int.tryParse(rawQ);
            String quarteirao = parsedQ != null
                ? parsedQ.toString().padLeft(2, '0')
                : "S/Q";
            String rua =
                (im['endereco'] == null ||
                    im['endereco'].toString().trim().isEmpty)
                ? "Rua Não Informada"
                : im['endereco'].toString();
            if (!agrupado.containsKey(quarteirao)) agrupado[quarteirao] = {};
            if (!agrupado[quarteirao]!.containsKey(rua))
              agrupado[quarteirao]![rua] = [];
            agrupado[quarteirao]![rua]!.add(im);
          }

          List<String> quarteiroes = agrupado.keys.toList();
          quarteiroes.sort((a, b) {
            int? numA = int.tryParse(a);
            int? numB = int.tryParse(b);
            if (numA != null && numB != null) return numA.compareTo(numB);
            if (numA != null) return -1;
            if (numB != null) return 1;
            return a.compareTo(b);
          });

          return ListView.builder(
            itemCount: quarteiroes.length,
            itemBuilder: (context, index) {
              String q = quarteiroes[index];
              var ruasMap = agrupado[q]!;
              List<String> ruas = ruasMap.keys.toList()..sort();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 3,
                child: ExpansionTile(
                  initiallyExpanded: false,
                  leading: Icon(
                    widget.apenasPE ? Icons.factory : Icons.grid_4x4,
                    color: ruas.isEmpty
                        ? Colors.grey
                        : (widget.apenasPE ? Colors.red : Colors.orange),
                  ),
                  title: Text(
                    'Quarteirão $q',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ruas.isEmpty
                          ? Colors.grey[700]
                          : (widget.apenasPE
                                ? Colors.red[900]
                                : Colors.orange[900]),
                    ),
                  ),
                  subtitle: Text(
                    ruas.isEmpty
                        ? 'Vazio'
                        : '${ruas.fold<int>(0, (sum, rua) => sum + ruasMap[rua]!.length)} imóveis',
                    style: TextStyle(
                      color: ruas.isEmpty ? Colors.grey : Colors.black54,
                    ),
                  ),
                  backgroundColor: ruas.isEmpty
                      ? Colors.grey[100]
                      : (widget.apenasPE ? Colors.red[50] : Colors.orange[50]),
                  children: ruas.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "Nenhum imóvel mapeado neste quarteirão.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ]
                      : ruas.map((rua) {
                          List<dynamic> imoveisDaRua = ruasMap[rua]!;
                          imoveisDaRua.sort(
                            (a, b) =>
                                (int.tryParse(a['numero']?.toString() ?? '0') ??
                                        0)
                                    .compareTo(
                                      int.tryParse(
                                          b['numero']?.toString() ?? '0',
                                        ) ??
                                        0,
                                    ),
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: Colors.grey[300],
                                child: Text(
                                  '📍 $rua',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              ...imoveisDaRua.map((im) {
                                String numero =
                                    (im['numero'] == null || im['numero'] == "")
                                    ? "S/N"
                                    : im['numero'];
                                String tipo = im['tipo'] ?? 'R';
                                bool isNovoOffline = im['id']
                                    .toString()
                                    .startsWith('TEMP');
                                return ListTile(
                                  leading: Icon(
                                    tipo == 'PE' ? Icons.factory : Icons.home,
                                    color: isNovoOffline
                                        ? Colors.deepPurple
                                        : Colors.blue,
                                  ),
                                  title: Text(
                                    'Nº $numero | Tipo: $tipo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isNovoOffline
                                          ? Colors.deepPurple
                                          : Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isNovoOffline
                                        ? 'NOVO (Aguardando Sincronização)'
                                        : 'ID do Imóvel: ${im['id']}',
                                  ),
                                  trailing: isNovoOffline
                                      ? const Icon(
                                          Icons.cloud_off,
                                          color: Colors.deepPurple,
                                        )
                                      : Icon(
                                          Icons.add_circle,
                                          color: widget.apenasPE
                                              ? Colors.red
                                              : Colors.orange,
                                        ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => TelaVisita(
                                        imovelId: im['id'],
                                        enderecoDisplay: "$rua, $numero",
                                        cicloId: widget.cicloId,
                                        semanaId: widget.semanaId,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// HISTÓRICO AGRUPADO
// =============================================================================
class TelaHistoricoVisitas extends StatefulWidget {
  final List<Map<String, dynamic>> semanas;
  const TelaHistoricoVisitas({super.key, required this.semanas});
  @override
  State<TelaHistoricoVisitas> createState() => _TelaHistoricoVisitasState();
}

class _TelaHistoricoVisitasState extends State<TelaHistoricoVisitas> {
  Map<String, dynamic>? _semanaSelecionada;

  Future<Map<String, Map<String, Map<String, Map<String, dynamic>>>>>
  _buscarAgrupado() async {
    List<dynamic> visitas = [];
    List<dynamic> imoveis = [];
    try {
      final respV = await http
          .get(
            Uri.parse('$baseUrl/api/visitas/'),
            headers: {"ngrok-skip-browser-warning": "true"},
          )
          .timeout(const Duration(seconds: 5));
      final respI = await http
          .get(
            Uri.parse('$baseUrl/api/imoveis/'),
            headers: {"ngrok-skip-browser-warning": "true"},
          )
          .timeout(const Duration(seconds: 5));
      await DatabaseHelper.instance.salvarCache(
        'visitas',
        utf8.decode(respV.bodyBytes),
      );
      await DatabaseHelper.instance.salvarCache(
        'imoveis',
        utf8.decode(respI.bodyBytes),
      );
      visitas = jsonDecode(utf8.decode(respV.bodyBytes));
      imoveis = jsonDecode(utf8.decode(respI.bodyBytes));
    } catch (e) {
      final cacheV = await DatabaseHelper.instance.lerCache('visitas');
      final cacheI = await DatabaseHelper.instance.lerCache('imoveis');
      if (cacheV != null && cacheI != null) {
        visitas = jsonDecode(cacheV);
        imoveis = jsonDecode(cacheI);
      } else {
        throw Exception('Sem dados offline salvos.');
      }
    }

    final visitasPendentes = await DatabaseHelper.instance
        .buscarVisitasPendentes();
    for (var vp in visitasPendentes) {
      visitas.add({
        "id": "PENDENTE (Offline)",
        "imovel": vp['imovel'],
        "status": vp['status'],
        "semana_epidemiologica": vp['semana_epidemiologica'],
        "data_visita": vp['data_visita'] ?? DateTime.now().toIso8601String(),
        "amostras_coletadas": vp['amostras_coletadas'],
        "quantidade_larvas": vp['quantidade_larvas'],
      });
    }

    if (_semanaSelecionada != null)
      visitas = visitas
          .where(
            (v) => v['semana_epidemiologica'] == _semanaSelecionada!['semana'],
          )
          .toList();

    Map<String, dynamic> mapaImoveis = {
      for (var im in imoveis) im['id'].toString(): im,
    };
    final imPendentes = await DatabaseHelper.instance.buscarImoveisPendentes();
    for (var ip in imPendentes) {
      mapaImoveis["TEMP_${ip['id_local']}"] = ip;
    }

    Map<String, Map<String, Map<String, Map<String, dynamic>>>> agrupado = {};

    for (var v in visitas) {
      var im = mapaImoveis[v['imovel'].toString()];
      if (im == null) continue;
      String bairro = im['bairro'] ?? "Sem Bairro";
      String rawQ = im['quarteirao']?.toString().trim() ?? "";
      int? parsedQ = int.tryParse(rawQ);
      String quarteirao = parsedQ != null
          ? parsedQ.toString().padLeft(2, '0')
          : "S/Q";
      String rua =
          (im['endereco'] == null || im['endereco'].toString().trim().isEmpty)
          ? "Rua Não Informada"
          : im['endereco'].toString();
      String numero =
          (im['numero'] == null || im['numero'].toString().trim().isEmpty)
          ? "S/N"
          : im['numero'].toString();
      String tipo = im['tipo'] ?? 'R';
      String imId = v['imovel'].toString();

      if (!agrupado.containsKey(bairro)) agrupado[bairro] = {};
      if (!agrupado[bairro]!.containsKey(quarteirao))
        agrupado[bairro]![quarteirao] = {};
      if (!agrupado[bairro]![quarteirao]!.containsKey(rua))
        agrupado[bairro]![quarteirao]![rua] = {};
      if (!agrupado[bairro]![quarteirao]![rua]!.containsKey(imId)) {
        agrupado[bairro]![quarteirao]![rua]![imId] = {
          "imovel_completo": im,
          "endereco_completo": "$rua, $numero",
          "numero": numero,
          "tipo": tipo,
          "visitas": [],
        };
      }
      agrupado[bairro]![quarteirao]![rua]![imId]!['visitas'].add(v);
    }
    return agrupado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico Agrupado'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<Map<String, dynamic>>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar por Semana Epidemiológica',
                prefixIcon: Icon(Icons.calendar_month, color: Colors.green),
              ),
              initialValue: _semanaSelecionada,
              items: [
                const DropdownMenuItem<Map<String, dynamic>>(
                  value: null,
                  child: Text('Todas as Semanas do Ano'),
                ),
                ...widget.semanas
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text('Semana ${s['semana']} (${s['inicio']})'),
                      ),
                    )
                    .toList(),
              ],
              onChanged: (v) => setState(() => _semanaSelecionada = v),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, Map<String, Map<String, Map<String, dynamic>>>>>(
              future: _buscarAgrupado(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(
                    child: Text('Nenhum dado salvo no celular.'),
                  );
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final dados = snapshot.data!;
                final bairros = dados.keys.toList()..sort();
                if (bairros.isEmpty)
                  return const Center(
                    child: Text(
                      'Nenhuma visita registrada.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );

                return ListView.builder(
                  itemCount: bairros.length,
                  itemBuilder: (context, index) {
                    String bairro = bairros[index];
                    var quarteiroesDoBairro = dados[bairro]!;
                    int totalVisitasBairro = 0;
                    quarteiroesDoBairro.values.forEach((ruas) {
                      ruas.values.forEach((imoveis) {
                        imoveis.values.forEach((imovel) {
                          totalVisitasBairro +=
                              (imovel['visitas'] as List).length;
                        });
                      });
                    });
                    List<String> quarteiroes = quarteiroesDoBairro.keys
                        .toList();
                    quarteiroes.sort((a, b) {
                      int? numA = int.tryParse(a);
                      int? numB = int.tryParse(b);
                      if (numA != null && numB != null)
                        return numA.compareTo(numB);
                      if (numA != null) return -1;
                      if (numB != null) return 1;
                      return a.compareTo(b);
                    });

                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.green[50],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                bairro.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[700],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$totalVisitasBairro VISITAS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...quarteiroes.map((q) {
                          var ruasMap = quarteiroesDoBairro[q]!;
                          List<String> ruas = ruasMap.keys.toList()..sort();
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            elevation: 2,
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              leading: const Icon(
                                Icons.grid_4x4,
                                color: Colors.green,
                              ),
                              title: Text(
                                'Quarteirão $q',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green[900],
                                ),
                              ),
                              backgroundColor: Colors.green[50]?.withOpacity(
                                0.5,
                              ),
                              children: ruas.map((rua) {
                                var imoveisMap = ruasMap[rua]!;
                                List<String> imoveisIds = imoveisMap.keys
                                    .toList();
                                imoveisIds.sort((a, b) {
                                  int numA =
                                      int.tryParse(
                                        imoveisMap[a]!['numero'].toString(),
                                      ) ??
                                      0;
                                  int numB =
                                      int.tryParse(
                                        imoveisMap[b]!['numero'].toString(),
                                      ) ??
                                      0;
                                  return numA.compareTo(numB);
                                });
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      color: Colors.grey[200],
                                      child: Text(
                                        '📍 $rua',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    ...imoveisIds.map((imId) {
                                      var infoImovel = imoveisMap[imId]!;
                                      List<dynamic> visitasDaCasa =
                                          infoImovel['visitas'];
                                      visitasDaCasa.sort(
                                        (a, b) => (b['data_visita'] ?? '')
                                            .compareTo(a['data_visita'] ?? ''),
                                      );
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ExpansionTile(
                                          leading: Icon(
                                            infoImovel['tipo'] == 'PE'
                                                ? Icons.factory
                                                : Icons.home,
                                            color: Colors.blue,
                                          ),
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Nº ${infoImovel['numero']} | Tipo: ${infoImovel['tipo']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.orange,
                                                  size: 20,
                                                ),
                                                tooltip: 'Editar Imóvel',
                                                onPressed: () async {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (c) =>
                                                          TelaCadastroImovel(
                                                            nomeBairro: bairro,
                                                            imovelExistente:
                                                                infoImovel['imovel_completo'],
                                                          ),
                                                    ),
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                            ],
                                          ),
                                          subtitle: Text(
                                            'Visitas: ${visitasDaCasa.length}',
                                          ),
                                          children: visitasDaCasa.map((v) {
                                            String dataFormatada =
                                                "Data não registrada";
                                            if (v['data_visita'] != null) {
                                              try {
                                                DateTime dt = DateTime.parse(
                                                  v['data_visita'],
                                                ).toLocal();
                                                dataFormatada =
                                                    "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                              } catch (e) {
                                                dataFormatada =
                                                    v['data_visita'];
                                              }
                                            }
                                            bool isPendente = v['id']
                                                .toString()
                                                .contains('PENDENTE');
                                            return ListTile(
                                              dense: true,
                                              isThreeLine: true,
                                              title: Text(
                                                'Visita ID: ${v['id']} - Status: ${v['status']}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isPendente
                                                      ? Colors.deepPurple
                                                      : Colors.black,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '📅 $dataFormatada\nTubitos: ${v['amostras_coletadas'] ?? 0}',
                                              ),
                                              trailing: isPendente
                                                  ? const Icon(
                                                      Icons.cloud_off,
                                                      color: Colors.deepPurple,
                                                    )
                                                  : const Icon(
                                                      Icons.check_circle,
                                                      size: 18,
                                                      color: Colors.green,
                                                    ),
                                              onTap: isPendente
                                                  ? null
                                                  : () async {
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (c) =>
                                                              TelaVisita(
                                                                imovelId:
                                                                    v['imovel'],
                                                                enderecoDisplay:
                                                                    infoImovel['endereco_completo'],
                                                                visitaExistente:
                                                                    v,
                                                              ),
                                                        ),
                                                      );
                                                      setState(() {});
                                                    },
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FORMULÁRIO DE VISITA
// =============================================================================
class TelaVisita extends StatefulWidget {
  final dynamic imovelId;
  final String? enderecoDisplay;
  final Map<String, dynamic>? visitaExistente;
  final int? cicloId;
  final int? semanaId;
  const TelaVisita({
    super.key,
    required this.imovelId,
    this.enderecoDisplay,
    this.visitaExistente,
    this.cicloId,
    this.semanaId,
  });
  @override
  State<TelaVisita> createState() => _TelaVisitaState();
}

class _TelaVisitaState extends State<TelaVisita> {
  bool enviando = false;
  late TextEditingController _agente,
      _depA1,
      _depA2,
      _depB,
      _depC,
      _depD1,
      _depD2,
      _depE,
      _tubitos,
      _larvas,
      _elim,
      _larv1t,
      _larv1q,
      _larv1d,
      _larv2t,
      _larv2q,
      _larv2d,
      _adultt,
      _adultq,
      _obs;
  String _status = 'N';
  int _totalDepositos = 0;

  void _calcularTotalDepositos() {
    setState(() {
      _totalDepositos =
          (int.tryParse(_depA1.text) ?? 0) +
          (int.tryParse(_depA2.text) ?? 0) +
          (int.tryParse(_depB.text) ?? 0) +
          (int.tryParse(_depC.text) ?? 0) +
          (int.tryParse(_depD1.text) ?? 0) +
          (int.tryParse(_depD2.text) ?? 0) +
          (int.tryParse(_depE.text) ?? 0);
    });
  }

  @override
  void initState() {
    super.initState();
    var v = widget.visitaExistente;
    _agente = TextEditingController(text: v?['agente']?.toString() ?? '1');
    _depA1 = TextEditingController(text: v?['dep_A1']?.toString() ?? '0');
    _depA2 = TextEditingController(text: v?['dep_A2']?.toString() ?? '0');
    _depB = TextEditingController(text: v?['dep_B']?.toString() ?? '0');
    _depC = TextEditingController(text: v?['dep_C']?.toString() ?? '0');
    _depD1 = TextEditingController(text: v?['dep_D1']?.toString() ?? '0');
    _depD2 = TextEditingController(text: v?['dep_D2']?.toString() ?? '0');
    _depE = TextEditingController(text: v?['dep_E']?.toString() ?? '0');
    _tubitos = TextEditingController(
      text: v?['amostras_coletadas']?.toString() ?? '0',
    );
    _larvas = TextEditingController(
      text: v?['quantidade_larvas']?.toString() ?? '0',
    );
    _elim = TextEditingController(
      text: v?['depositos_eliminados']?.toString() ?? '0',
    );
    _larv1t = TextEditingController(text: v?['larvicida_1_tipo'] ?? '');
    _larv1q = TextEditingController(
      text: v?['larvicida_1_qtde']?.toString() ?? '0',
    );
    _larv1d = TextEditingController(
      text: v?['larvicida_1_dep_tratados']?.toString() ?? '0',
    );
    _larv2t = TextEditingController(text: v?['larvicida_2_tipo'] ?? '');
    _larv2q = TextEditingController(
      text: v?['larvicida_2_qtde']?.toString() ?? '0',
    );
    _larv2d = TextEditingController(
      text: v?['larvicida_2_dep_tratados']?.toString() ?? '0',
    );
    _adultt = TextEditingController(text: v?['adulticida_tipo'] ?? '');
    _adultq = TextEditingController(
      text: v?['adulticida_qtde']?.toString() ?? '0',
    );
    _obs = TextEditingController(text: v?['observacoes'] ?? '');
    if (v != null) _status = v['status'];
    _calcularTotalDepositos();
    [
      _depA1,
      _depA2,
      _depB,
      _depC,
      _depD1,
      _depD2,
      _depE,
    ].forEach((c) => c.addListener(_calcularTotalDepositos));
  }

  Widget _bloco(String t, Color c, List<Widget> f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...f,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boletim Diário PNCD'),
        backgroundColor: Colors.orange[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.enderecoDisplay != null)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey[200],
                child: Text(
                  '🏠 ${widget.enderecoDisplay}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status da Visita'),
              items: const [
                DropdownMenuItem(
                  value: 'N',
                  child: Text('Normal (Inspecionado)'),
                ),
                DropdownMenuItem(value: 'F', child: Text('Fechada')),
                DropdownMenuItem(value: 'R', child: Text('Recusada')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 15),
            _bloco('Depósitos Inspecionados', Colors.orange[50]!, [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _depA1,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'A1'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _depA2,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'A2'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _depB,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'B'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _depC,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'C'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _depD1,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'D1'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _depD2,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'D2'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _depE,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'E (Natural)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange[200],
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.orange[400]!),
                      ),
                      child: Center(
                        child: Text(
                          'Total:\n$_totalDepositos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
            _bloco('Coleta e Ações', Colors.blue[50]!, [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tubitos,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tubitos'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _larvas,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Larvas'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _elim,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Eliminados',
                      ),
                    ),
                  ),
                ],
              ),
            ]),
            _bloco('Tratamento Focal (Larvicida)', Colors.green[50]!, [
              TextFormField(
                controller: _larv1t,
                decoration: const InputDecoration(
                  labelText: 'Larvicida (1) Tipo',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _larv1q,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Gramas'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      controller: _larv1d,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dep. Tratados',
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              TextFormField(
                controller: _larv2t,
                decoration: const InputDecoration(
                  labelText: 'Larvicida (2) Tipo',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _larv2q,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Gramas'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      controller: _larv2d,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dep. Tratados',
                      ),
                    ),
                  ),
                ],
              ),
            ]),
            _bloco('Tratamento Perifocal', Colors.purple[50]!, [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _adultt,
                      decoration: const InputDecoration(
                        labelText: 'Adulticida Tipo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      controller: _adultq,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cargas'),
                    ),
                  ),
                ],
              ),
            ]),
            TextFormField(
              controller: _obs,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      setState(() => enviando = true);
                      try {
                        String nomeAgenteCache = await DatabaseHelper.instance
                            .lerCache('agente_logado') ?? "";

                        var d = {
                          "status": _status,
                          "imovel":
                              widget.visitaExistente?['imovel'] ??
                              widget.imovelId.toString(),
                          "agente_username": nomeAgenteCache,
                          "agente": 1,
                          "amostras_coletadas": int.parse(
                            _tubitos.text.isEmpty ? '0' : _tubitos.text,
                          ),
                          "quantidade_larvas": int.parse(
                            _larvas.text.isEmpty ? '0' : _larvas.text,
                          ),
                          "depositos_eliminados": int.parse(
                            _elim.text.isEmpty ? '0' : _elim.text,
                          ),
                          "larvicida_1_tipo": _larv1t.text,
                          "larvicida_1_qtde": double.parse(
                            _larv1q.text.replaceAll(',', '.') == ""
                                ? "0"
                                : _larv1q.text.replaceAll(',', '.'),
                          ),
                          "larvicida_1_dep_tratados": int.parse(
                            _larv1d.text.isEmpty ? '0' : _larv1d.text,
                          ),
                          "larvicida_2_tipo": _larv2t.text,
                          "larvicida_2_qtde": double.parse(
                            _larv2q.text.replaceAll(',', '.') == ""
                                ? "0"
                                : _larv2q.text.replaceAll(',', '.'),
                          ),
                          "larvicida_2_dep_tratados": int.parse(
                            _larv2d.text.isEmpty ? '0' : _larv2d.text,
                          ),
                          "adulticida_tipo": _adultt.text,
                          "adulticida_qtde": double.parse(
                            _adultq.text.replaceAll(',', '.') == ""
                                ? "0"
                                : _adultq.text.replaceAll(',', '.'),
                          ),
                          "observacoes": _obs.text,
                          "dep_A1": int.parse(
                            _depA1.text.isEmpty ? '0' : _depA1.text,
                          ),
                          "dep_A2": int.parse(
                            _depA2.text.isEmpty ? '0' : _depA2.text,
                          ),
                          "dep_B": int.parse(
                            _depB.text.isEmpty ? '0' : _depB.text,
                          ),
                          "dep_C": int.parse(
                            _depC.text.isEmpty ? '0' : _depC.text,
                          ),
                          "dep_D1": int.parse(
                            _depD1.text.isEmpty ? '0' : _depD1.text,
                          ),
                          "dep_D2": int.parse(
                            _depD2.text.isEmpty ? '0' : _depD2.text,
                          ),
                          "dep_E": int.parse(
                            _depE.text.isEmpty ? '0' : _depE.text,
                          ),
                        };
                        if (widget.visitaExistente == null &&
                            widget.cicloId != null &&
                            widget.semanaId != null) {
                          d["ciclo"] = widget.cicloId!;
                          d["semana_epidemiologica"] = widget.semanaId!;
                          d["data_visita"] = DateTime.now().toIso8601String();
                        }
                        var url = widget.visitaExistente != null
                            ? '$baseUrl/api/visitas/${widget.visitaExistente!['id']}/'
                            : '$baseUrl/api/visitas/';
                        try {
                          if (widget.visitaExistente != null) {
                            await http
                                .put(
                                  Uri.parse(url),
                                  headers: {
                                    "Content-Type": "application/json",
                                    "ngrok-skip-browser-warning": "true",
                                  },
                                  body: jsonEncode(d),
                                )
                                .timeout(const Duration(seconds: 5));
                          } else {
                            await http
                                .post(
                                  Uri.parse(url),
                                  headers: {
                                    "Content-Type": "application/json",
                                    "ngrok-skip-browser-warning": "true",
                                  },
                                  body: jsonEncode(d),
                                )
                                .timeout(const Duration(seconds: 5));
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Visita enviada ao servidor com sucesso!',
                              ),
                            ),
                          );
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          if (widget.visitaExistente == null) {
                            try {
                              await DatabaseHelper.instance.inserirVisita(d);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Visita salva no Modo Offline! Sincronize na base.',
                                  ),
                                  backgroundColor: Colors.deepPurple,
                                ),
                              );
                              if (mounted) Navigator.pop(context);
                            } catch (eBanco) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Erro no Banco Offline: $eBanco',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() => enviando = false);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sem internet para editar visita. Tente mais tarde.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => enviando = false);
                          }
                        }
                      } catch (eGeral) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verifique os campos numéricos.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() => enviando = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
              child: const Text(
                'SALVAR BOLETIM OFICIAL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// RELATÓRIOS
// =============================================================================
class TelaRelatorios extends StatefulWidget {
  final List<Map<String, dynamic>> bairros;
  final List<Map<String, dynamic>> semanas;
  const TelaRelatorios({
    super.key,
    required this.bairros,
    required this.semanas,
  });
  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  Map<String, dynamic>? _bairroSelecionado;
  Map<String, dynamic>? _semanaSelecionada;
  bool _carregando = false;
  Map<String, dynamic>? _dadosRelatorio;
  String _tipoRelatorio = 'Rotina Geral (Inclui PE)';

  Future<void> _gerarResumo() async {
    if (_bairroSelecionado == null || _semanaSelecionada == null) return;
    setState(() => _carregando = true);
    try {
      List<dynamic> visitas = [];
      List<dynamic> imoveis = [];
      try {
        final respV = await http
            .get(
              Uri.parse('$baseUrl/api/visitas/'),
              headers: {"ngrok-skip-browser-warning": "true"},
            )
            .timeout(const Duration(seconds: 5));
        final respI = await http
            .get(
              Uri.parse('$baseUrl/api/imoveis/'),
              headers: {"ngrok-skip-browser-warning": "true"},
            )
            .timeout(const Duration(seconds: 5));
        await DatabaseHelper.instance.salvarCache(
          'visitas',
          utf8.decode(respV.bodyBytes),
        );
        await DatabaseHelper.instance.salvarCache(
          'imoveis',
          utf8.decode(respI.bodyBytes),
        );
        visitas = jsonDecode(utf8.decode(respV.bodyBytes));
        imoveis = jsonDecode(utf8.decode(respI.bodyBytes));
      } catch (e) {
        final cacheV = await DatabaseHelper.instance.lerCache('visitas');
        final cacheI = await DatabaseHelper.instance.lerCache('imoveis');
        if (cacheV != null && cacheI != null) {
          visitas = jsonDecode(cacheV);
          imoveis = jsonDecode(cacheI);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Atenção: Relatório gerado com base em dados offline limitados.',
              ),
              backgroundColor: Colors.deepPurple,
            ),
          );
        } else {
          setState(() => _carregando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sem internet e sem cache salvo para gerar relatório.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      Map<int, dynamic> mapaImoveis = {for (var im in imoveis) im['id']: im};
      int tRes = 0,
          tCom = 0,
          tTB = 0,
          tPE = 0,
          tOutro = 0,
          tInsp = 0,
          tFechado = 0,
          tRecusa = 0,
          sA1 = 0,
          sA2 = 0,
          sB = 0,
          sC = 0,
          sD1 = 0,
          sD2 = 0,
          sE = 0,
          sTubitos = 0,
          sElim = 0;

      for (var v in visitas) {
        if (v['semana_epidemiologica'] == _semanaSelecionada!['semana']) {
          var imovelRelacionado = mapaImoveis[v['imovel']];
          if (imovelRelacionado != null &&
              imovelRelacionado['bairro'] == _bairroSelecionado!['nome']) {
            String tipo = imovelRelacionado['tipo'] ?? 'R';
            if (_tipoRelatorio == 'Apenas PE' && tipo != 'PE') continue;

            if (tipo == 'R')
              tRes++;
            else if (tipo == 'C')
              tCom++;
            else if (tipo == 'TB')
              tTB++;
            else if (tipo == 'PE')
              tPE++;
            else
              tOutro++;
            if (v['status'] == 'N')
              tInsp++;
            else if (v['status'] == 'F')
              tFechado++;
            else if (v['status'] == 'R')
              tRecusa++;
            sA1 += (v['dep_A1'] as int? ?? 0);
            sA2 += (v['dep_A2'] as int? ?? 0);
            sB += (v['dep_B'] as int? ?? 0);
            sC += (v['dep_C'] as int? ?? 0);
            sD1 += (v['dep_D1'] as int? ?? 0);
            sD2 += (v['dep_D2'] as int? ?? 0);
            sE += (v['dep_E'] as int? ?? 0);
            sTubitos += (v['amostras_coletadas'] as int? ?? 0);
            sElim += (v['depositos_eliminados'] as int? ?? 0);
          }
        }
      }
      setState(() {
        _dadosRelatorio = {
          "Residencia": tRes,
          "Comercio": tCom,
          "TB": tTB,
          "PE": tPE,
          "Outros": tOutro,
          "TotalImoveis": (tRes + tCom + tTB + tPE + tOutro),
          "Inspecionados": tInsp,
          "Fechados": tFechado,
          "Recusados": tRecusa,
          "A1": sA1,
          "A2": sA2,
          "B": sB,
          "C": sC,
          "D1": sD1,
          "D2": sD2,
          "E": sE,
          "TotalDepositos": (sA1 + sA2 + sB + sC + sD1 + sD2 + sE),
          "Tubitos": sTubitos,
          "Eliminados": sElim,
        };
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao processar os dados.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _linhaTabela(String titulo, String valor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo Semanal - PNCD'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Bairro'),
                    initialValue: _bairroSelecionado,
                    items: widget.bairros
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(b['nome']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _bairroSelecionado = v;
                      _dadosRelatorio = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Semana Epidemiológica',
                    ),
                    initialValue: _semanaSelecionada,
                    items: widget.semanas
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              'Semana ${s['semana']} (${s['inicio']})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _semanaSelecionada = v;
                      _dadosRelatorio = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Relatório',
                    ),
                    initialValue: _tipoRelatorio,
                    items: const [
                      DropdownMenuItem(
                        value: 'Rotina Geral (Inclui PE)',
                        child: Text('Rotina Geral (Inclui PE)'),
                      ),
                      DropdownMenuItem(
                        value: 'Apenas PE',
                        child: Text('Apenas Pontos Estratégicos (PE)'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _tipoRelatorio = v!;
                      _dadosRelatorio = null;
                    }),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed:
                        (_bairroSelecionado == null ||
                            _semanaSelecionada == null ||
                            _carregando)
                        ? null
                        : _gerarResumo,
                    icon: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.calculate, color: Colors.white),
                    label: const Text(
                      'Calcular Fechamento',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (_dadosRelatorio != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.black12,
                child: Text(
                  'Vila Rica - MT | Bairro: ${_bairroSelecionado!['nome']} | Semana: ${_semanaSelecionada!['semana']}\nTipo: ${_tipoRelatorio.toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nº IMÓVEIS TRABALHADOS POR TIPO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(thickness: 2),
                      _linhaTabela(
                        'Residência',
                        _dadosRelatorio!['Residencia'].toString(),
                      ),
                      _linhaTabela(
                        'Comércio',
                        _dadosRelatorio!['Comercio'].toString(),
                      ),
                      _linhaTabela(
                        'Terreno Baldio (TB)',
                        _dadosRelatorio!['TB'].toString(),
                      ),
                      _linhaTabela(
                        'Ponto Estratégico (PE)',
                        _dadosRelatorio!['PE'].toString(),
                      ),
                      _linhaTabela(
                        'Outro',
                        _dadosRelatorio!['Outros'].toString(),
                      ),
                      const Divider(thickness: 2),
                      _linhaTabela(
                        'TOTAL GERAL',
                        _dadosRelatorio!['TotalImoveis'].toString(),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SITUAÇÃO / PENDÊNCIAS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(thickness: 2),
                      _linhaTabela(
                        'Inspecionados (Trat. Focal)',
                        _dadosRelatorio!['Inspecionados'].toString(),
                      ),
                      _linhaTabela(
                        'Recusa',
                        _dadosRelatorio!['Recusados'].toString(),
                      ),
                      _linhaTabela(
                        'Fechados',
                        _dadosRelatorio!['Fechados'].toString(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nº DEPÓSITOS INSPECIONADOS POR TIPO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(thickness: 2),
                      _linhaTabela(
                        'A1 (Caixa d\'água)',
                        _dadosRelatorio!['A1'].toString(),
                      ),
                      _linhaTabela(
                        'A2 (Outros armazenamentos)',
                        _dadosRelatorio!['A2'].toString(),
                      ),
                      _linhaTabela(
                        'B (Pequenos depósitos)',
                        _dadosRelatorio!['B'].toString(),
                      ),
                      _linhaTabela(
                        'C (Depósitos fixos)',
                        _dadosRelatorio!['C'].toString(),
                      ),
                      _linhaTabela(
                        'D1 (Pneus)',
                        _dadosRelatorio!['D1'].toString(),
                      ),
                      _linhaTabela(
                        'D2 (Lixo/Sucata)',
                        _dadosRelatorio!['D2'].toString(),
                      ),
                      _linhaTabela(
                        'E (Natural)',
                        _dadosRelatorio!['E'].toString(),
                      ),
                      const Divider(thickness: 2),
                      _linhaTabela(
                        'TOTAL INSPECIONADO',
                        _dadosRelatorio!['TotalDepositos'].toString(),
                        isBold: true,
                      ),
                      const Divider(thickness: 2),
                      _linhaTabela(
                        'Depósitos Eliminados',
                        _dadosRelatorio!['Eliminados'].toString(),
                        isBold: true,
                      ),
                      _linhaTabela(
                        'Amostras (Tubitos) Coletadas',
                        _dadosRelatorio!['Tubitos'].toString(),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}