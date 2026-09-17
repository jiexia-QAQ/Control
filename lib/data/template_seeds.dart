import '../models/workout_template.dart';

/// 内置分化训练模板（首次启动种子）
List<WorkoutTemplate> templateSeeds() => [
      WorkoutTemplate(
        name: '三分化·推拉腿',
        cycleDays: 3,
        restAfter: 1,
        days: [
          TemplateDay(day: 1, exercises: [
            TemplateExercise(exerciseId: null, name: '杠铃卧推', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '上斜哑铃卧推', sets: 3, reps: 10),
            TemplateExercise(exerciseId: null, name: '绳索夹胸', sets: 3, reps: 12),
            TemplateExercise(exerciseId: null, name: '双杠臂屈伸', sets: 3, reps: 10),
            TemplateExercise(exerciseId: null, name: '绳索下压', sets: 3, reps: 12),
            TemplateExercise(exerciseId: null, name: '仰卧杠铃臂屈伸', sets: 3, reps: 10),
          ]),
          TemplateDay(day: 2, exercises: [
            TemplateExercise(exerciseId: null, name: '引体向上', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '高位下拉', sets: 4, reps: 10),
            TemplateExercise(exerciseId: null, name: '俯身杠铃划船', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '坐姿绳索划船', sets: 3, reps: 12),
            TemplateExercise(exerciseId: null, name: '杠铃弯举', sets: 3, reps: 10),
            TemplateExercise(exerciseId: null, name: '锤式弯举', sets: 3, reps: 12),
          ]),
          TemplateDay(day: 3, exercises: [
            TemplateExercise(exerciseId: null, name: '深蹲', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '腿举', sets: 4, reps: 10),
            TemplateExercise(exerciseId: null, name: '罗马尼亚硬拉', sets: 3, reps: 10),
            TemplateExercise(exerciseId: null, name: '俯卧腿弯举', sets: 3, reps: 12),
            TemplateExercise(exerciseId: null, name: '哑铃推举', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '侧平举', sets: 4, reps: 12),
          ]),
        ],
      ),
      WorkoutTemplate(
        name: '四分化·胸背腿肩',
        cycleDays: 4,
        restAfter: 1,
        days: [
          TemplateDay(day: 1, exercises: [
            TemplateExercise(exerciseId: null, name: '杠铃卧推', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '上斜杠铃卧推', sets: 3, reps: 10),
            TemplateExercise(exerciseId: null, name: '哑铃飞鸟', sets: 3, reps: 12),
            TemplateExercise(exerciseId: null, name: '双杠臂屈伸', sets: 3, reps: 10),
          ]),
          TemplateDay(day: 2, exercises: [
            TemplateExercise(exerciseId: null, name: '引体向上', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '俯身杠铃划船', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '单臂哑铃划船', sets: 3, reps: 10),
            TemplateExercise(exerciseId: null, name: '直臂下压', sets: 3, reps: 12),
          ]),
          TemplateDay(day: 3, exercises: [
            TemplateExercise(exerciseId: null, name: '深蹲', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '罗马尼亚硬拉', sets: 3, reps: 10),
            TemplateExercise(exerciseId: null, name: '腿屈伸', sets: 3, reps: 12),
            TemplateExercise(exerciseId: null, name: '站姿提踵', sets: 4, reps: 15),
          ]),
          TemplateDay(day: 4, exercises: [
            TemplateExercise(exerciseId: null, name: '哑铃推举', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '侧平举', sets: 4, reps: 12),
            TemplateExercise(exerciseId: null, name: '俯身飞鸟', sets: 3, reps: 12),
            TemplateExercise(exerciseId: null, name: '面拉', sets: 3, reps: 15),
          ]),
        ],
      ),
      WorkoutTemplate(
        name: '五分化·胸背肩腿臂',
        cycleDays: 5,
        restAfter: 1,
        days: [
          TemplateDay(day: 1, exercises: [
            TemplateExercise(exerciseId: null, name: '杠铃卧推', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '上斜哑铃卧推', sets: 4, reps: 10),
            TemplateExercise(exerciseId: null, name: '绳索夹胸', sets: 3, reps: 12),
          ]),
          TemplateDay(day: 2, exercises: [
            TemplateExercise(exerciseId: null, name: '引体向上', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '俯身杠铃划船', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '坐姿绳索划船', sets: 3, reps: 12),
          ]),
          TemplateDay(day: 3, exercises: [
            TemplateExercise(exerciseId: null, name: '哑铃推举', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '侧平举', sets: 4, reps: 12),
            TemplateExercise(exerciseId: null, name: '俯身飞鸟', sets: 3, reps: 12),
          ]),
          TemplateDay(day: 4, exercises: [
            TemplateExercise(exerciseId: null, name: '深蹲', sets: 4, reps: 8),
            TemplateExercise(exerciseId: null, name: '腿举', sets: 4, reps: 10),
            TemplateExercise(exerciseId: null, name: '俯卧腿弯举', sets: 4, reps: 12),
          ]),
          TemplateDay(day: 5, exercises: [
            TemplateExercise(exerciseId: null, name: '杠铃弯举', sets: 4, reps: 10),
            TemplateExercise(exerciseId: null, name: '锤式弯举', sets: 3, reps: 12),
            TemplateExercise(exerciseId: null, name: '绳索下压', sets: 4, reps: 12),
            TemplateExercise(exerciseId: null, name: '窄距卧推', sets: 3, reps: 10),
          ]),
        ],
      ),
    ];
