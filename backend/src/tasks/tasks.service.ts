import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, isValidObjectId } from 'mongoose';
import { Task, TaskDocument } from './schemas/task.schema';
import { CreateTaskDto } from './dto/create-task.dto';
import { TaskResponseDto } from './dto/task-response.dto';

@Injectable()
export class TasksService {
  constructor(
    @InjectModel(Task.name) private readonly taskModel: Model<TaskDocument>,
  ) {}

  async create(dto: CreateTaskDto): Promise<TaskResponseDto> {
    const created = await this.taskModel.create({
      title: dto.title.trim(),
      completed: false,
    });
    return this.toResponse(created);
  }

  async findAll(): Promise<TaskResponseDto[]> {
    const tasks = await this.taskModel.find().sort({ createdAt: -1 }).exec();
    return tasks.map((t) => this.toResponse(t));
  }

  async complete(id: string): Promise<TaskResponseDto> {
    // Guard against malformed ids before hitting MongoDB, so we return a
    // clean 400 instead of letting the driver throw a CastError.
    if (!isValidObjectId(id)) {
      throw new BadRequestException(`"${id}" is not a valid task id`);
    }

    const updated = await this.taskModel
      .findByIdAndUpdate(id, { completed: true }, { new: true })
      .exec();

    if (!updated) {
      throw new NotFoundException(`Task with id "${id}" was not found`);
    }

    return this.toResponse(updated);
  }

  private toResponse(doc: TaskDocument): TaskResponseDto {
    return {
      id: doc._id.toString(),
      title: doc.title,
      completed: doc.completed,
      createdAt: (doc as any).createdAt,
      updatedAt: (doc as any).updatedAt,
    };
  }
}
