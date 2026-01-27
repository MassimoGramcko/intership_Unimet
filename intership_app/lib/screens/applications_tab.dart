import 'package:flutter/material.dart';
import '../config/theme.dart';

class ApplicationsTab extends StatelessWidget {
  const ApplicationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Título de la sección
        const Text(
          "Historial de Postulaciones",
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: AppTheme.secondaryBlue
          ),
        ),
        const SizedBox(height: 16),

        // CASO 1: Postulación EN REVISIÓN (Nestlé)
        _buildApplicationCard(
          company: "Nestlé Venezuela",
          position: "Analista de Datos",
          date: "Hace 2 días",
          statusStep: 2, // 1: Enviado, 2: En Revisión, 3: Finalizado
          statusLabel: "En Revisión",
          statusColor: Colors.orange,
        ),

        // CASO 2: Postulación APROBADA (Polar)
        _buildApplicationCard(
          company: "Empresas Polar",
          position: "Pasante de Producción",
          date: "Hace 1 semana",
          statusStep: 3, 
          statusLabel: "Pre-Seleccionado",
          statusColor: Colors.green,
          isApproved: true,
        ),

        // CASO 3: Postulación RECHAZADA (Banco Mercantil)
        _buildApplicationCard(
          company: "Banco Mercantil",
          position: "Asistente de Finanzas",
          date: "Hace 2 semanas",
          statusStep: 3,
          statusLabel: "No seleccionado",
          statusColor: Colors.red,
          isRejected: true,
        ),
      ],
    );
  }

  Widget _buildApplicationCard({
    required String company,
    required String position,
    required String date,
    required int statusStep,
    required String statusLabel,
    required Color statusColor,
    bool isApproved = false,
    bool isRejected = false,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de la tarjeta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(company, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Línea de tiempo visual (Stepper simplificado)
            Row(
              children: [
                _buildStep(1, statusStep, "Enviado", isRejected),
                _buildLine(1, statusStep),
                _buildStep(2, statusStep, "En Revisión", isRejected),
                _buildLine(2, statusStep),
                _buildStep(3, statusStep, isApproved ? "Aprobado" : (isRejected ? "Rechazado" : "Final"), isRejected, isFinal: true),
              ],
            ),
            
            const SizedBox(height: 12),
            // Mensaje de estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Circulito del paso
  Widget _buildStep(int stepIndex, int currentStep, String label, bool isRejected, {bool isFinal = false}) {
    bool isActive = stepIndex <= currentStep;
    Color color;
    
    if (isActive) {
      if (isFinal && isRejected) {
        color = Colors.red;
      } else if (isFinal && !isRejected && currentStep == 3) {
        color = Colors.green;
      } else {
        color = AppTheme.primaryOrange;
      }
    } else {
      color = Colors.grey.shade300;
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: color,
          child: Icon(
            isActive ? (isFinal && isRejected ? Icons.close : Icons.check) : Icons.circle, 
            size: 12, 
            color: Colors.white
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.black : Colors.grey))
      ],
    );
  }

  // Línea conectora
  Widget _buildLine(int stepIndex, int currentStep) {
    return Expanded(
      child: Container(
        height: 2,
        color: stepIndex < currentStep ? AppTheme.primaryOrange : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10), // Alineado con el círculo
      ),
    );
  }
}